import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'dashboard_page.dart';

class PartnerConnectPage extends StatefulWidget {
  const PartnerConnectPage({super.key});

  @override
  State<PartnerConnectPage> createState() => _PartnerConnectPageState();
}

class _PartnerConnectPageState extends State<PartnerConnectPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _codeController = TextEditingController();
  bool _loading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final user = await _firestoreService.getUser(uid);
    if (mounted) setState(() => _currentUser = user);
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _linkPartner() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      _showMsg('Please enter a valid 6-character code', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final partner = await _firestoreService.findUserByInviteCode(code);
      if (partner == null) {
        _showMsg('No user found with that code', isError: true);
        return;
      }

      if (partner.uid == _currentUser?.uid) {
        _showMsg("You can't link with yourself!", isError: true);
        return;
      }

      if (partner.partnerId.isNotEmpty) {
        _showMsg('That user is already linked', isError: true);
        return;
      }

      await _firestoreService.linkPartner(
        currentUserId: _currentUser!.uid,
        partnerUserId: partner.uid,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      _showMsg(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Partner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ─── Your Code Section ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppTheme.accent,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Invite Code',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentUser?.inviteCode ?? '------',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_currentUser?.inviteCode != null) {
                          Clipboard.setData(
                            ClipboardData(text: _currentUser!.inviteCode),
                          );
                          _showMsg('Code copied to clipboard! 💕');
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(color: AppTheme.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // ─── Divider ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or enter partner\'s code',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.dividerColor)),
                ],
              ),

              const SizedBox(height: 32),

              // ─── Partner Code Input ────────────────────────────────
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    letterSpacing: 6,
                  ),
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppTheme.accent,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 28),

              _loading
                  ? const CircularProgressIndicator(color: AppTheme.accent)
                  : GradientButton(
                      label: 'Link with Partner 💕',
                      icon: Icons.link_rounded,
                      onPressed: _linkPartner,
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 40),

              // ─── Help Text ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share your code with your partner and ask them to enter it, or enter their code here.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
