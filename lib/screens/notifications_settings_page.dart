import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

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
            value: _pushEnabled,
            activeThumbColor: AppTheme.accent,
            onChanged: (val) async {
              setState(() => _pushEnabled = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', val);
            },
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Sound',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: _soundEnabled,
            activeThumbColor: AppTheme.accent,
            onChanged: (val) async {
              setState(() => _soundEnabled = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('sound_enabled', val);
            },
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Vibration',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: _vibrationEnabled,
            activeThumbColor: AppTheme.accent,
            onChanged: (val) async {
              setState(() => _vibrationEnabled = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('vibration_enabled', val);
            },
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }
}
