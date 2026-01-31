import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = FlutterSecureStorage();

  // Token methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'token');
  }

  // User ID methods
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'userId', value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  static Future<void> deleteUserId() async {
    await _storage.delete(key: 'userId');
  }

  // Clear all storage (for logout)
  // static Future<void> clearAll() async {
  //   await _storage.deleteAll();
  // }
}