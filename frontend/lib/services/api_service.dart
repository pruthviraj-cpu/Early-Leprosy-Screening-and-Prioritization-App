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

}
