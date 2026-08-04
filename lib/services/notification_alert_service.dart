import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'dart:ui' show AppLifecycleState;
import 'dart:async';

class NotificationAlertService {
  static final NotificationAlertService _instance =
      NotificationAlertService._internal();
  factory NotificationAlertService() => _instance;
  NotificationAlertService._internal();

  static bool isChatScreenActive = false;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _messagesSub;
  StreamSubscription? _pulsesSub;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return; // flutter_local_notifications doesn't fully support web with these settings
    }

    // Use default mipmap icon
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotificationsPlugin.initialize(settings: initSettings);

    // Create high-importance channel for Android
    const androidChannel = AndroidNotificationChannel(
      'deeptalks_alerts',
      'DeepTalks Alerts',
      description: 'Incoming messages and love pulses',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  void startListening(String currentUserId, String coupleId) {
    _messagesSub?.cancel();
    _pulsesSub?.cancel();

    // Listen to messages
    _messagesSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(coupleId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final senderId = data['senderId'] as String?;
          if (senderId != currentUserId) {
            // Firestore timestamps can be tricky regarding client time.
            // We use server timestamp normally, but checking if it's recent locally.
            final ts = data['timestamp'];
            if (ts is Timestamp) {
              final diff = DateTime.now().difference(ts.toDate());
              // Using 15 seconds to gracefully handle network slight delays.
              if (diff.inSeconds >= 0 && diff.inSeconds <= 15) {
                _triggerAlert(
                  title: 'New Message',
                  body: data['text'] ?? 'Sent you an attachment 📷',
                );
              }
            } else if (ts == null) {
              // If timestamp is null, it might be heavily pending, we can optionally trigger it if wanted.
              // Assuming it just arrived.
              _triggerAlert(
                title: 'New Message',
                body: data['text'] ?? 'Sent you an attachment 📷',
              );
            }
          }
        }
      }
    });

    // Listen to Love Pulses
    _pulsesSub = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('pulses')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final senderId = data['senderId'] as String?;
          if (senderId != currentUserId) {
            final ts = data['timestamp'];
            if (ts is Timestamp) {
              final diff = DateTime.now().difference(ts.toDate());
              if (diff.inSeconds >= 0 && diff.inSeconds <= 15) {
                _triggerAlert(
                  title: '❤️ Love Pulse',
                  body: 'Your partner sent you a Love Pulse!',
                  isPulse: true,
                );
              }
            } else if (ts == null) {
              _triggerAlert(
                title: '❤️ Love Pulse',
                body: 'Your partner sent you a Love Pulse!',
                isPulse: true,
              );
            }
          }
        }
      }
    });
  }

  Future<void> _triggerAlert(
      {required String title,
      required String body,
      bool isPulse = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!pushEnabled) return;

    final isResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    // We won't exit early for pulses being resumed anymore because we want them to vibrate!
    // But we will skip Standard Messages completely if resumed.
    if (isResumed && !isPulse) {
      return;
    }

    if (!kIsWeb) {
      final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      if (vibrationEnabled) {
        if (isPulse && (await Vibration.hasVibrator() == true)) {
          // Vibrate for a few seconds unconditionally
          Vibration.vibrate(
              pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000]);
        } else if (!isResumed) {
          // Normal haptic feedback only if not resumed
          HapticFeedback.heavyImpact();
        }
      }
    }

    if (kIsWeb) {
      print('WEB NOTIFICATION: $title - $body');
      return;
    }

    // ONLY SHOW UI NOTIFICATIONS IF THE APP IS OFF.
    // The user requested: "notification should only come when app is off"
    if (!isResumed) {
      const androidDetails = AndroidNotificationDetails(
          'deeptalks_alerts', 'DeepTalks Alerts',
          importance: Importance.max, priority: Priority.max, ticker: 'ticker');
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
      );
    }
  }

  void stopListening() {
    _messagesSub?.cancel();
    _pulsesSub?.cancel();
  }
}
