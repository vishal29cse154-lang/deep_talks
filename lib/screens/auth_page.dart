import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // Sign In fields
  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  // Sign Up fields
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();

  bool _loading = false;
  bool _obscureSignIn = true;
  bool _obscureSignUp = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_signInEmail.text.trim().isEmpty ||
        _signInPassword.text.trim().isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _signInEmail.text.trim(),
        password: _signInPassword.text.trim(),
      );
      // Navigation is handled by the auth state listener in main.dart
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_signUpEmail.text.trim().isEmpty ||
        _signUpPassword.text.trim().isEmpty) {
      _showError('Please fill in email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.signUp(
        email: _signUpEmail.text.trim(),
        password: _signUpPassword.text.trim(),
        displayName: _signUpName.text.trim(),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ─── Branding ────────────────────────────────────────
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'DeepTalks',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

              const SizedBox(height: 8),

              Text(
                'Your private space for love & memories',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 40),

              // ─── Tab Bar ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Create Account'),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 32),

              // ─── Tab Content ─────────────────────────────────────
              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildSignInForm(), _buildSignUpForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        TextField(
          controller: _signInEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accent),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signInPassword,
          obscureText: _obscureSignIn,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.accent),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignIn ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _obscureSignIn = !_obscureSignIn),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _loading
            ? const CircularProgressIndicator(color: AppTheme.accent)
            : GradientButton(
                label: 'Sign In',
                icon: Icons.login_rounded,
                onPressed: _signIn,
              ),
        const SizedBox(height: 20),
        _dividerWithText('or'),
        const SizedBox(height: 20),
        _googleButton(),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        TextField(
          controller: _signUpName,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Display Name',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.accent),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signUpEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accent),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signUpPassword,
          obscureText: _obscureSignUp,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.accent),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignUp ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _obscureSignUp = !_obscureSignUp),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _loading
            ? const CircularProgressIndicator(color: AppTheme.accent)
            : GradientButton(
                label: 'Create Account',
                icon: Icons.person_add_rounded,
                onPressed: _signUp,
              ),
        const SizedBox(height: 20),
        _dividerWithText('or'),
        const SizedBox(height: 20),
        _googleButton(),
      ],
    );
  }

  Widget _dividerWithText(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.dividerColor)),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _googleSignIn,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(color: AppTheme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
