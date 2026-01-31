import 'package:flutter/material.dart';
import './model/user_profile.dart';
import './service/profile_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService profileService;
  
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;
  
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSyncing => _isSyncing;
  
  ProfileController({
    required this.profileService,
  });
  
  /// Initialize with user ID
  Future<void> initialize(String userId, {bool fetchFromBackend = true}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await profileService.initialize(userId);
      _profile = await profileService.loadProfile(fetchFromBackend: fetchFromBackend);
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    String? phoneNumber,
  }) async {
    if (_profile == null) return;
    
    _isSaving = true;
    notifyListeners();
    
    try {
      _profile = await profileService.updateProfile(
        userId: _profile!.id,
        fullName: fullName,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  /// Force sync with backend
  Future<void> syncProfile() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      final syncedProfile = await profileService.syncWithBackend();
      if (syncedProfile != null) {
        _profile = syncedProfile;
      }
    } catch (e) {
      print('Error syncing profile: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Clear profile (logout)
  Future<void> clearProfile() async {
    await profileService.clearProfile();
    _profile = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}