import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'service_account.dart';

class PushNotificationSender {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  static Future<String?> _getAccessToken() async {
    if (ServiceAccountCredentials.credentials.isEmpty ||
        !ServiceAccountCredentials.credentials.containsKey('project_id')) {
      print(
          '⚠️ PushNotificationSender Error: service_account.dart is empty or invalid.');
      return null;
    }

    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(
        ServiceAccountCredentials.credentials,
      );

      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      print('⚠️ PushNotificationSender Auth Error: $e');
      return null;
    }
  }

  /// Sends a push notification or love pulse directly from the client to the partner's FCM token.
  static Future<void> sendPush({
    required String fcmToken,
    required String title,
    required String body,
    required String type,
    String? coupleId,
  }) async {
    final projectId = ServiceAccountCredentials.credentials['project_id'];
    if (projectId == null) {
      print('Cannot send push: project_id not found in service_account.dart');
      return;
    }

    final token = await _getAccessToken();
    if (token == null) return;

    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    final messagePayload = {
      'message': {
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'deeptalks_alerts',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
            }
          }
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': type,
          if (coupleId != null) 'coupleId': coupleId,
        }
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(messagePayload),
      );

      if (response.statusCode == 200) {
        print('✅ FCM Delivered: $title');
      } else {
        print('❌ FCM Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ FCM Exception: $e');
    }
  }
}
