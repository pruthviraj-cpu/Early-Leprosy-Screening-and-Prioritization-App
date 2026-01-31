import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class ApiService {
  static const String baseUrl = "https://skin-buddy.onrender.com/api";

  static Future<String> sendChat(String message) async {
  final token = await SecureStorage.getToken();

  if (token == null) {
    throw Exception("No auth token found");
  }

  final res = await http.post(
    Uri.parse('$baseUrl/chat'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // 🔥 REQUIRED
    },
    body: jsonEncode({
      'message': message,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Unauthorized or chat failed");
  }

  final data = jsonDecode(res.body);
  return data['reply'];
}

static Future<Map<String, dynamic>> getProfile() async {
  final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/profile/me'),
      headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // 🔥 REQUIRED
    },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String? fullName,
    required int? age,
    required String? gender,
    required String? phoneNumber,
  }) async {
    final body = {
      if (fullName != null) 'full_name': fullName,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (phoneNumber != null) 'phone': phoneNumber,
    };
    final token = await SecureStorage.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/profile/me'),
      headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // 🔥 REQUIRED
    },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

}
