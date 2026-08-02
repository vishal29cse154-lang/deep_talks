import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'auth_page.dart';

class SettingsPage extends StatelessWidget {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  SettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<UserModel?>(
              stream: _firestoreService.userStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }

                final user = snapshot.data;
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.surfaceDark,
                            backgroundImage: user?.photoUrl.isNotEmpty == true
                                ? NetworkImage(user!.photoUrl)
                                : null,
                            child: user?.photoUrl.isEmpty == true
                                ? Text(
                                    user?.displayName.isNotEmpty == true
                                        ? user!.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? 'Anonymous User',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Preferences (Placeholder for future)
                    const Text(
                      'PREFERENCES',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.notifications_rounded,
                          color: AppTheme.accent),
                      title: const Text('Notifications',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      tileColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.security_rounded,
                          color: AppTheme.accent),
                      title: const Text('Privacy & Security',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      tileColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onTap: () {},
                    ),
                    const SizedBox(height: 40),

                    // Logout Button
                    ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon:
                          const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                );
              },
            ),
    );
  }
}
