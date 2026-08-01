import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';
import 'screens/auth_page.dart';
import 'screens/partner_connect_page.dart';
import 'screens/dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <-- ADD THIS LINE HERE!
  );
  runApp(
    const DeepTalksApp(),
  ); // (Keep whatever runApp line is already below it)
}

class DeepTalksApp extends StatelessWidget {
  const DeepTalksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepTalks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const AuthGate(),
    );
  }
}

/// Routing guard that listens to auth state and navigates accordingly:
///   - Not signed in  → AuthPage
///   - Signed in, no partner → PartnerConnectPage
///   - Signed in, has partner → DashboardPage
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnap) {
        // ─── Loading ──────────────────────────────────────────────
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          );
        }

        // ─── Not Signed In ───────────────────────────────────────
        if (authSnap.data == null) {
          return const AuthPage();
        }

        // ─── Signed In – Check partner status ────────────────────
        return StreamBuilder<UserModel?>(
          stream: FirestoreService().userStream(authSnap.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              );
            }

            final user = userSnap.data;
            if (user == null || user.partnerId.isEmpty) {
              return const PartnerConnectPage();
            }

            return const DashboardPage();
          },
        );
      },
    );
  }
}
