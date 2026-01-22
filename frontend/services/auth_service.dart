import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // static const String baseUrl = 'http://10.0.2.2:3000/auth';
  static const String baseUrl = 'http://localhost:5000/api/auth';


  /// SIGN UP
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw data['error'] ?? 'Signup failed';
    }
  }

  /// LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw data['error'] ?? 'Login failed';
    }
  }
}