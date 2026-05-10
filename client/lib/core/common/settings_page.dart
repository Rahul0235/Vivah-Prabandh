import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../features/auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  final UserModel user;

  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // ─── Notification Preferences ─────────────────────────────────────────────
  bool _emailNotifications    = true;
  bool _reminderNotifications = true;
  bool _bookingNotifications  = true;
  bool _promotionalEmails     = false;

  // ─── Privacy Options ──────────────────────────────────────────────────────
  bool _showProfile          = true;
  bool _showContact          = true;
  bool _showLocation         = false;
  bool _allowDataCollection  = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications    = prefs.getBool('emailNotifications')    ?? true;
      _reminderNotifications = prefs.getBool('reminderNotifications') ?? true;
      _bookingNotifications  = prefs.getBool('bookingNotifications')  ?? true;
      _promotionalEmails     = prefs.getBool('promotionalEmails')     ?? false;
      _showProfile           = prefs.getBool('showProfile')           ?? true;
      _showContact           = prefs.getBool('showContact')           ?? true;
      _showLocation          = prefs.getBool('showLocation')          ?? false;
      _allowDataCollection   = prefs.getBool('allowDataCollection')   ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text("Logout"),
          ],
        ),
        content: const Text(
          "Are you sure you want to logout from your account?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Vivah Prabandh collects and uses your data solely to provide wedding planning services. "
            "We do not sell your personal information to third parties. "
            "Your data is stored securely and used to improve your experience on the platform.\n\n"
            "By using our services, you agree to our data collection practices as described in this policy.",
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text("Delete Account"),
          ],
        ),
        content: const Text(
          "This action is permanent and cannot be undone. All your data including events, guests, budget and bookings will be deleted.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account deletion request submitted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // ── No Scaffold — just the content so no back arrow appears ──────────────
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Page Header ────────────────────────────────────
                    Text('Settings',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Manage your preferences and account',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),

                    // ── Profile Summary Card ───────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: Text(
                                widget.user.name.isNotEmpty
                                    ? widget.user.name[0].toUpperCase()
                                    : "U",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(widget.user.email,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Notification Preferences ───────────────────────
                    _buildSectionHeader(context, 'Notification Preferences',
                        Icons.notifications_outlined),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _buildToggleTile(context,
                              icon: Icons.email_outlined,
                              title: 'Email Notifications',
                              subtitle: 'Receive updates and alerts via email',
                              value: _emailNotifications,
                              onChanged: (val) {
                                setState(() => _emailNotifications = val);
                                _savePreference('emailNotifications', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.alarm_outlined,
                              title: 'Reminder Notifications',
                              subtitle:
                                  'Get reminders for upcoming events and tasks',
                              value: _reminderNotifications,
                              onChanged: (val) {
                                setState(() => _reminderNotifications = val);
                                _savePreference('reminderNotifications', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.book_online_outlined,
                              title: 'Booking Notifications',
                              subtitle:
                                  'Alerts for booking confirmations and updates',
                              value: _bookingNotifications,
                              onChanged: (val) {
                                setState(() => _bookingNotifications = val);
                                _savePreference('bookingNotifications', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.campaign_outlined,
                              title: 'Promotional Emails',
                              subtitle: 'Receive offers and platform news',
                              value: _promotionalEmails,
                              onChanged: (val) {
                                setState(() => _promotionalEmails = val);
                                _savePreference('promotionalEmails', val);
                              }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Privacy Options ────────────────────────────────
                    _buildSectionHeader(
                        context, 'Privacy Options', Icons.lock_outline),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _buildToggleTile(context,
                              icon: Icons.person_outline,
                              title: 'Show Profile',
                              subtitle: 'Allow others to view your profile',
                              value: _showProfile,
                              onChanged: (val) {
                                setState(() => _showProfile = val);
                                _savePreference('showProfile', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.phone_outlined,
                              title: 'Show Contact Info',
                              subtitle:
                                  'Display your contact details to vendors',
                              value: _showContact,
                              onChanged: (val) {
                                setState(() => _showContact = val);
                                _savePreference('showContact', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.location_on_outlined,
                              title: 'Show Location',
                              subtitle: 'Share your location with vendors',
                              value: _showLocation,
                              onChanged: (val) {
                                setState(() => _showLocation = val);
                                _savePreference('showLocation', val);
                              }),
                          _buildDivider(),
                          _buildToggleTile(context,
                              icon: Icons.analytics_outlined,
                              title: 'Allow Data Collection',
                              subtitle:
                                  'Help us improve by sharing usage data',
                              value: _allowDataCollection,
                              onChanged: (val) {
                                setState(() => _allowDataCollection = val);
                                _savePreference('allowDataCollection', val);
                              }),
                          _buildDivider(),
                          _buildActionTile(context,
                              icon: Icons.policy_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              onTap: _showPrivacyPolicy),
                          _buildDivider(),
                          _buildActionTile(context,
                              icon: Icons.delete_forever_outlined,
                              title: 'Delete Account',
                              subtitle:
                                  'Permanently delete your account and data',
                              onTap: _showDeleteAccountDialog,
                              color: Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Account ────────────────────────────────────────
                    _buildSectionHeader(
                        context, 'Account', Icons.manage_accounts_outlined),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _buildActionTile(context,
                              icon: Icons.info_outline,
                              title: 'App Version',
                              subtitle: 'Vivah Prabandh v1.0.0',
                              onTap: () {},
                              showArrow: false),
                          _buildDivider(),
                          _buildActionTile(context,
                              icon: Icons.logout,
                              title: 'Logout',
                              subtitle: 'Sign out from your account',
                              onTap: _handleLogout,
                              color: Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56);

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    bool showArrow = true,
  }) {
    final tileColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: tileColor),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: color)),
      subtitle: Text(subtitle,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
      trailing: showArrow
          ? Icon(Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.3))
          : null,
    );
  }
}