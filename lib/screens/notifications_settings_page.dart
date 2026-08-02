import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text('Push Notifications',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Enable alerts for messages and love pulses',
                style: TextStyle(color: AppTheme.textSecondary)),
            value: true,
            activeColor: AppTheme.accent,
            onChanged: (val) {},
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Sound',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: true,
            activeColor: AppTheme.accent,
            onChanged: (val) {},
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Vibration',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: true,
            activeColor: AppTheme.accent,
            onChanged: (val) {},
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }
}
