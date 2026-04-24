import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecureStorage {
  static final _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'userId', value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> saveIsProfileCompleted(bool isCompleted) async {
    await _storage.write(
      key: 'is_profile_completed',
      value: isCompleted.toString(),
    );
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}