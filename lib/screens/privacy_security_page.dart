import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
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
            title: const Text('View-Once Protection',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Prevent screenshots of view-once media',
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
            title: const Text('Incognito Keyboard',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Disable keyboard learning in private chats',
                style: TextStyle(color: AppTheme.textSecondary)),
            value: true,
            activeColor: AppTheme.accent,
            onChanged: (val) {},
            tileColor: AppTheme.cardDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('Clear Chat History',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
