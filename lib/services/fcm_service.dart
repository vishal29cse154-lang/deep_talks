import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
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
        log('Message data: ${message.data}');

        if (message.notification != null) {
          _localNotifications.show(
            id: message.notification.hashCode,
            title: message.notification!.title,
            body: message.notification!.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/launcher_icon',
              ),
            ),
          );
        }
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
    }
  }

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
