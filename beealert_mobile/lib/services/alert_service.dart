import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Global alerts (admin broadcast) ───────────────────────────────────────

  Stream<List<AlertModel>> getAlerts() {
    return _db
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AlertModel.fromDoc(d)).toList());
  }

  // ── Per-user notifications (from admin actions) ────────────────────────────

  Stream<List<AlertModel>> getUserNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AlertModel.fromDoc(d)).toList());
  }

  /// Merged stream: global alerts + per-user notifications, sorted newest-first
  Stream<List<AlertModel>> getAllNotifications(String uid) {
    return Rx.combineLatest2<List<AlertModel>, List<AlertModel>, List<AlertModel>>(
      getAlerts(),
      getUserNotifications(uid),
      (global, personal) {
        final merged = [...personal, ...global];
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return merged;
      },
    );
  }

  // ── Unread count (personal unread + global count) ──────────────────────────

  Stream<int> getUnreadCount({String? uid}) {
    if (uid == null) {
      return _db
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots()
          .map((snap) => snap.docs.length);
    }

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, int>(
      _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      _db
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      (personalSnap, globalSnap) =>
          personalSnap.docs.length + globalSnap.docs.length,
    );
  }

  // ── Mark a personal notification as read ──────────────────────────────────

  Future<void> markRead(String uid, String notificationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all personal notifications as read
  Future<void> markAllRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
