import 'package:hive/hive.dart';
import '../model/user_profile.dart';

class ProfileCacheService {
  static Box<UserProfile>? _profileBox;

  /// Open profile box for user
  Future<void> openUserProfileBox(String userId) async {
    final boxName = 'profile_$userId';

    if (Hive.isBoxOpen(boxName)) {
      _profileBox = Hive.box<UserProfile>(boxName);
    } else {
      _profileBox = await Hive.openBox<UserProfile>(boxName);
    }
  }

  /// Get user profile
  Future<UserProfile?> getProfile() async {
    if (_profileBox == null || _profileBox!.isEmpty) return null;
    return _profileBox!.getAt(0);
  }

  /// Save or update profile
  Future<void> saveProfile(UserProfile profile) async {
    if (_profileBox == null) return;
    
    if (_profileBox!.isEmpty) {
      await _profileBox!.add(profile);
    } else {
      await _profileBox!.putAt(0, profile);
    }
  }

  /// Clear profile (logout)
  Future<void> clearProfile() async {
    if (_profileBox != null) {
      await _profileBox!.clear();
    }
  }

  /// Close profile box
  Future<void> closeProfileBox() async {
    await _profileBox?.close();
    _profileBox = null;
  }
}