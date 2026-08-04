import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vibration/vibration.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');

  // If the app is completely terminated and we get a love pulse via FCM
  // we can manually trigger the vibration here. The native OS will separately paint the notification banner.
  try {
    if (message.data['type'] == 'love_pulse') {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000]);
      }
    }
  } catch (e) {
    log('FCM Vibration error: $e');
  }
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // ─── Native App Notifications (Web lacks full native setup) ───
    if (kIsWeb) {
      log('FCM not fully supported on Web yet, skipping init for testing.');
      return;
    }

    // Request permission (Apple & Web)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted FCM permission');

      // Initialize local notifications for frontend heads-up alerts
      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidInitSettings);

      await _localNotifications.initialize(settings: initSettings);

      // Create high importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');

        // Let NotificationAlertService handle foreground notifications or
        // suppress here so we don't show heads-up for chat messages while in app.
        // We will just let the app update its UI.
      });

      // Handle Background Messages via top-level function
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Save token to DB
      _saveDeviceToken();

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((token) {
        _updateTokenInDb(token);
      });

      // ─── Setup Firestore listener for "Love Pulse" ───
      // We removed this since NotificationAlertService already handles Love Pulses universally.
      // _listenForLovePulses();
    }
  }

  // (Listeners moved to NotificationAlertService for centralized logic)

  Future<void> _saveDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        _updateTokenInDb(token);
      }
    } catch (e) {
      log('Failed to get FCM token: $e');
    }
  }

  Future<void> _updateTokenInDb(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
      log('Saved FCM Token: $token');
    }
  }
}
