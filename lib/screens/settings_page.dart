import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../widgets/profile_photo_viewer.dart';
import 'auth_page.dart';
import 'notifications_settings_page.dart';
import 'privacy_security_page.dart';

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

  Future<void> _showRenameDialog(BuildContext context, String uid,
      String currentName, String title) async {
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _firestoreService.updateUserDisplayName(uid, newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                          GestureDetector(
                            onTap: () {
                              if (user?.photoUrl.isNotEmpty == true) {
                                ProfilePhotoViewer.show(
                                  context: context,
                                  heroTag: 'settings_avatar_${user!.uid}',
                                  photoUrl: user.photoUrl,
                                  displayName: user.safeDisplayName,
                                );
                              }
                            },
                            child: Hero(
                              tag: 'settings_avatar_${user?.uid}',
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.surfaceDark,
                                backgroundImage:
                                    user?.photoUrl.isNotEmpty == true
                                        ? NetworkImage(user!.photoUrl)
                                        : null,
                                child: user?.photoUrl.isEmpty == true
                                    ? Text(
                                        user?.safeDisplayName.isNotEmpty == true
                                            ? user!.safeDisplayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            user?.safeDisplayName ?? 'Anonymous User',
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

                    // Profile Controls
                    const Text(
                      'PROFILES',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.person_rounded,
                          color: AppTheme.accent),
                      title: const Text('Change My Name',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: const Icon(Icons.edit_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      tileColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onTap: () {
                        if (user != null) {
                          _showRenameDialog(context, user.uid,
                              user.safeDisplayName, 'Change My Name');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.favorite_rounded,
                          color: AppTheme.accent),
                      title: const Text('Change Partner\'s Name',
                          style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: const Icon(Icons.edit_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      tileColor: AppTheme.cardDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onTap: () {
                        if (user != null && user.partnerId.isNotEmpty) {
                          _showRenameDialog(context, user.partnerId, '',
                              'Change Partner\'s Name');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No partner paired yet.')));
                        }
                      },
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
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsSettingsPage()));
                      },
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
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacySecurityPage()));
                      },
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
