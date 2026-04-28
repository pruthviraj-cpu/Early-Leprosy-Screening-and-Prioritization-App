import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/secure_storage.dart';

class FCMService {
  static Future<void> init() async {
    // 1. Request permission
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();

    print("Permission: ${settings.authorizationStatus}");

    // 2. Get token
    String? token = await FirebaseMessaging.instance.getToken();
    print("DEVICE TOKEN: $token");

    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // 3. Listen for token refresh (IMPORTANT)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("NEW TOKEN: $newToken");
      await _sendTokenToBackend(newToken);
    });

    // 4. Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground notification: ${message.notification?.title}");
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await SecureStorage.getToken();

      await http.post(
        Uri.parse("https://skin-buddy.onrender.com/api/save-device-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "device_token": token,
        }),
      );

      print("Token sent to backend");
    } catch (e) {
      print("Error sending token: $e");
    }
  }
}