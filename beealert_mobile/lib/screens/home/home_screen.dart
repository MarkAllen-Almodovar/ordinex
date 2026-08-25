import 'package:flutter/material.dart';
import '../../widgets/app_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/alert_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/report_card.dart';
import '../reports/my_reports_screen.dart';
import '../reports/report_detail_screen.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  final AlertService _alertService = AlertService();

  UserModel? _userProfile;
  bool _profileLoading = true;

  /// Live contacts from Firestore â€” falls back to hardcoded constants
  List<MunicipalContact> _contacts = municipalContacts;

  final List<Widget> _tabs = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('contacts')
          .get();
      if (!mounted) return;
      if (snap.exists) {
        final raw = snap.data()?['contacts'];
        if (raw is List && raw.isNotEmpty) {
          final loaded = raw
              .whereType<Map<String, dynamic>>()
              .map((m) => MunicipalContact(
                    name:  m['name']  as String? ?? '',
                    phone: m['phone'] as String? ?? '',
                    email: m['email'] as String? ?? '',
                  ))
              .where((c) => c.name.isNotEmpty || c.phone.isNotEmpty)
              .toList();
          if (loaded.isNotEmpty) {
            setState(() => _contacts = loaded);
          }
        }
      }
    } catch (_) {
      // Firestore unavailable â€” keep hardcoded fallback silently
    }
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
        _userProfile = profile;
        _profileLoading = false;
      });
      }
    } else {
      setState(() => _profileLoading = false);
    }
  }

  void _onNavTap(int index) => setState(() => _currentIndex = index);

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const MyReportsScreen(embedded: true);
      case 2:
        return const AlertsScreen(embedded: true);
      case 3:
        return ProfileScreen(userProfile: _userProfile, embedded: true);
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firstName = _userProfile?.fullName.split(' ').first ?? 'Resident';

    return CustomScrollView(
      slivers: [
        // Gradient header
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            const AppLogo(size: 22, blendWithBackground: false),
                            const SizedBox(width: 6),
                            const Text('BEE-Alert',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        StreamBuilder<int>(
                          stream: _alertService.getUnreadCount(uid: uid),
                          builder: (ctx, snap) {
                            final count = snap.data ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white),
                                  onPressed: () =>
                                      setState(() => _currentIndex = 2),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, $firstName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      municipality,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Report button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/report-form'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradientStart,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Report Concern',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _currentIndex = 1),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: gradientStart),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.assignment_outlined,
                            color: gradientStart, size: 18),
                        label: const Text('My Reports',
                            style: TextStyle(color: gradientStart)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _currentIndex = 2),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: gradientStart),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_outlined,
                            color: gradientStart, size: 18),
                        label: const Text('View Alerts',
                            style: TextStyle(color: gradientStart)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Municipal Contacts
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Municipal Contacts',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _contacts.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: gradientStart.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business_outlined,
                                  color: gradientStart, size: 20),
                            ),
                            title: Text(c.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(c.phone,
                                style: const TextStyle(
                                    fontSize: 12, color: gradientStart)),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone,
                                  color: gradientStart, size: 20),
                              onPressed: () async {
                                final uri = Uri.parse(
                                    'tel:${c.phone.replaceAll(RegExp(r'[^\d+]'), '')}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                          ),
                          if (i < _contacts.length - 1)
                            const Divider(height: 1, indent: 56),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent Reports
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Reports',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('See All',
                      style: TextStyle(color: gradientStart)),
                ),
              ],
            ),
          ),
        ),

        StreamBuilder<List<ReportModel>>(
          stream: _reportService.getRecentReports(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: gradientStart),
                )),
              );
            }
            final reports = snap.data ?? [];
            if (reports.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No reports yet',
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey)),
                      SizedBox(height: 4),
                      Text(
                          'Tap "Report Concern" to submit your first report.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => ReportCard(
                  report: reports[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        report: reports[i],
                      ),
                    ),
                  ),
                ),
                childCount: reports.length,
              ),
            );
          },
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _profileLoading
          ? const Center(
              child: CircularProgressIndicator(color: gradientStart))
          : _buildBody(),
      bottomNavigationBar: BeeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
