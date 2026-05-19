import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await NotificationService.instance.isRemindersEnabled();
    if (mounted) setState(() { _remindersEnabled = enabled; _loadingPrefs = false; });
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _remindersEnabled = value);
    await NotificationService.instance.setRemindersEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value
            ? 'Appointment reminders enabled'
            : 'Appointment reminders disabled'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('App Info', [
                  _tile(Icons.info_outline, 'App Name',
                      'GenSalon – General Salon Manager'),
                  _tile(Icons.tag, 'Version', '1.0.0'),
                ]),
                const SizedBox(height: 16),
                _section('Notifications', [
                  SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.purple.withOpacity(0.15),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.purple, size: 20),
                    ),
                    title: const Text('Appointment Reminders',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text(
                        'Get notified 30 min before appointments',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    value: _remindersEnabled,
                    activeColor: AppColors.purple,
                    onChanged: _toggleReminders,
                  ),
                ]),
                const SizedBox(height: 16),
                _section('Data', [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x26EF4444),
                      child: Icon(Icons.delete_sweep_outlined,
                          color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Clear All Data',
                        style: TextStyle(color: Color(0xFFEF4444))),
                    subtitle: const Text('Permanently delete all records',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    onTap: () => _confirmClear(context),
                  ),
                ]),
                const SizedBox(height: 32),
                const Center(
                  child: Text('Made with ❤ for GenSalon',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        backgroundColor: AppColors.purple.withOpacity(0.15),
        child: Icon(icon, color: AppColors.purple, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all clients, staff, appointments and sales. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared successfully.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
