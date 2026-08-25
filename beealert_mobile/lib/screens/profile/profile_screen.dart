import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../reports/my_reports_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel? userProfile;
  final bool embedded;

  const ProfileScreen({
    super.key,
    this.userProfile,
    this.embedded = false,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out of BEE-Alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (r) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign out failed. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final reportService = ReportService();
    final name = userProfile?.fullName ?? 'Resident';
    final phone = userProfile?.phoneNumber ?? '';
    final barangay = userProfile?.barangay ?? '';

    Widget body = Column(
      children: [
        // Header
        Container(
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  if (barangay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'ðŸ“ Brgy. $barangay',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats row
                StreamBuilder<List<ReportModel>>(
                  stream: reportService.getUserReports(uid),
                  builder: (ctx, snap) {
                    final reports = snap.data ?? [];
                    final total = reports.length;
                    final pending = reports
                        .where((r) => r.status == statusPending)
                        .length;
                    final resolved = reports
                        .where((r) => r.status == statusCompleted)
                        .length;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _statItem('$total', 'Total Reports',
                              gradientStart),
                          _divider(),
                          _statItem('$pending', 'Pending',
                              colorPending),
                          _divider(),
                          _statItem('$resolved', 'Resolved',
                              colorCompleted),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Menu
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.assignment_outlined,
                        label: 'My Reports',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const MyReportsScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _menuItemToggle(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Settings',
                      ),
                      const Divider(height: 1, indent: 56),
                      _menuItem(
                        icon: Icons.info_outline,
                        label: 'About BEE-Alert',
                        onTap: () => _showAbout(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _menuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => _showPrivacy(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _menuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        color: Colors.red,
                        onTap: () => _confirmSignOut(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'BEE-Alert v1.0.0\nMunicipality of Bacnotan, La Union',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), body: body);
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.grey.shade200,
      );

  Widget _menuItem({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? gradientStart, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: color ?? const Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _menuItemToggle({
    required IconData icon,
    required String label,
  }) {
    return _SwitchTile(icon: icon, label: label);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About BEE-Alert'),
        content: const SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('BEE-Alert v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 8),
          Text('The official community concern reporting app of the Municipality of Bacnotan, La Union.\n\nBEE-Alert empowers residents to:\n- Submit and track concern reports\n- Receive real-time updates from LGU officials\n- Access emergency hotlines quickly\n\nDeveloped for Bacnotan, La Union.', style: TextStyle(fontSize: 13, height: 1.6)),
        ],),),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style:
                ElevatedButton.styleFrom(backgroundColor: gradientStart),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'BEE-Alert collects personal information including your name, phone number, barangay, and location data solely for the purpose of processing community concern reports. '
            'Your data is shared only with authorized Bacnotan LGU officials. '
            'We do not sell or share your information with third parties. '
            'Photos attached to reports may include location metadata. '
            'By using BEE-Alert, you consent to this data collection and use.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style:
                ElevatedButton.styleFrom(backgroundColor: gradientStart),
            child: const Text('Close'),
          ),
        ],
      ),
    );

  }
}

// ── Simple toggle tile ───────────────────────────────────────────────────────

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String label;
  const _SwitchTile({required this.icon, required this.label});

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: gradientStart, size: 22),
      title: Text(
        widget.label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: _enabled,
        activeThumbColor: gradientStart,
        onChanged: (v) => setState(() => _enabled = v),
      ),
    );
  }
}
