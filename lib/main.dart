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
import 'services/fcm_service.dart';
import 'services/notification_alert_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Push Notifications
  final fcm = FCMService();
  await fcm.initialize();

  // Initialize Global Alert Listener
  final alertService = NotificationAlertService();
  await alertService.initialize();

  runApp(
    const DeepTalksApp(),
  );
}

class DeepTalksApp extends StatefulWidget {
  const DeepTalksApp({super.key});

  @override
  State<DeepTalksApp> createState() => _DeepTalksAppState();
}

class _DeepTalksAppState extends State<DeepTalksApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (state == AppLifecycleState.resumed) {
        FirestoreService().updatePresence(user.uid, true);
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached) {
        FirestoreService().updatePresence(user.uid, false);
      }
    }
  }

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
