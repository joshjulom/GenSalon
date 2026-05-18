import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('App Info', [
            _tile(Icons.info_outline, 'App Name', 'GenSalon – General Salon Manager'),
            _tile(Icons.tag, 'Version', '1.0.0'),
          ]),
          const SizedBox(height: 16),
          _section('Notifications', [
            _switchTile(
              context,
              Icons.notifications_outlined,
              'Appointment Reminders',
              'Get notified 30 min before appointments',
              true,
            ),
          ]),
          const SizedBox(height: 16),
          _section('Data', [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const CircleAvatar(
                backgroundColor: Color(0x26EF4444),
                child: Icon(Icons.delete_sweep_outlined,
                    color: Color(0xFFEF4444), size: 20),
              ),
              title: const Text('Clear All Data',
                  style: TextStyle(color: Color(0xFFEF4444))),
              subtitle: const Text('Permanently delete all records',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () => _confirmClear(context),
            ),
          ]),
          const SizedBox(height: 32),
          const Center(
            child: Text('Made with ❤ for GenSalon',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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

  Widget _switchTile(BuildContext context, IconData icon, String title,
      String subtitle, bool value) {
    return StatefulBuilder(builder: (_, set) {
      return SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        secondary: CircleAvatar(
          backgroundColor: AppColors.purple.withOpacity(0.15),
          child: Icon(icon, color: AppColors.purple, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        value: value,
        activeColor: AppColors.purple,
        onChanged: (v) => set(() {}),
      );
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete all clients, staff, appointments and sales. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
