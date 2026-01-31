import '../model/user_profile.dart';
import '../service/profile_cache_service.dart';
import '../../../services/api_service.dart';

class ProfileService {
  final ProfileCacheService cacheService;

  ProfileService(this.cacheService);

  /// Initialize profile with user ID
  Future<void> initialize(String userId) async {
    await cacheService.openUserProfileBox(userId);
  }

  /// Load profile from cache AND fetch from backend
  Future<UserProfile?> loadProfile({bool fetchFromBackend = true}) async {
    // First load from cache
    UserProfile? cachedProfile = await cacheService.getProfile();
    
    if (fetchFromBackend) {
      try {
        // Try to fetch from backend
        final backendData = await ApiService.getProfile();
        
        // Create or update profile from backend data
        final backendProfile = UserProfile(
          id: backendData['id'] ?? cachedProfile?.id ?? '',
          fullName: backendData['full_name'],
          age: backendData['age'],
          gender: backendData['gender'],
          email: backendData['email'], // Note: email might come from auth, not profile table
          phoneNumber: backendData['phone'],
          profileImageUrl: backendData['profile_image_url'],
          createdAt: backendData['created_at'] != null 
              ? DateTime.parse(backendData['created_at'])
              : cachedProfile?.createdAt,
          updatedAt: backendData['updated_at'] != null 
              ? DateTime.parse(backendData['updated_at'])
              : DateTime.now(),
        );
        
        // Save to cache
        await saveProfile(backendProfile);
        
        return backendProfile;
      } catch (e) {
        print('Failed to fetch profile from backend: $e');
        // Return cached profile if backend fetch fails
        return cachedProfile;
      }
    }
    
    return cachedProfile;
  }

  /// Save profile to cache
  Future<void> saveProfile(UserProfile profile) async {
    profile.updatedAt = DateTime.now();
    if (profile.createdAt == null) {
      profile.createdAt = DateTime.now();
    }
    await cacheService.saveProfile(profile);
  }

  /// Update profile and sync with backend
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    int? age,
    String? gender,
    String? phoneNumber,
  }) async {
    final existingProfile = await loadProfile(fetchFromBackend: false);
    
    final updatedProfile = existingProfile ?? UserProfile(id: userId);
    
    // Only update fields that are provided
    if (fullName != null) updatedProfile.fullName = fullName;
    if (age != null) updatedProfile.age = age;
    if (gender != null) updatedProfile.gender = gender;
    if (phoneNumber != null) updatedProfile.phoneNumber = phoneNumber;
    
    updatedProfile.updatedAt = DateTime.now();

    try {
      // Sync with backend first (if online)
      final backendResponse = await ApiService.updateProfile(
        fullName: fullName ?? updatedProfile.fullName,
        age: age ?? updatedProfile.age,
        gender: gender ?? updatedProfile.gender,
        phoneNumber: phoneNumber ?? updatedProfile.phoneNumber,
      );
      
      // Update with backend response data
      if (backendResponse['full_name'] != null) {
        updatedProfile.fullName = backendResponse['full_name'];
      }
      if (backendResponse['age'] != null) {
        updatedProfile.age = backendResponse['age'];
      }
      if (backendResponse['gender'] != null) {
        updatedProfile.gender = backendResponse['gender'];
      }
      if (backendResponse['phone'] != null) {
        updatedProfile.phoneNumber = backendResponse['phone'];
      }
      if (backendResponse['updated_at'] != null) {
        updatedProfile.updatedAt = DateTime.parse(backendResponse['updated_at']);
      }
      
    } catch (e) {
      print('Failed to sync profile with backend: $e');
      // Profile will be saved locally for offline access
      // Mark for sync later if needed
    }

    // Save to cache (whether sync succeeded or failed)
    await saveProfile(updatedProfile);

    return updatedProfile;
  }

  /// Clear profile data (on logout)
  Future<void> clearProfile() async {
    await cacheService.clearProfile();
  }

  /// Force sync with backend (for manual sync)
  Future<UserProfile?> syncWithBackend() async {
    try {
      final existingProfile = await loadProfile(fetchFromBackend: false);
      if (existingProfile == null) return null;
      
      final backendData = await ApiService.getProfile();
      
      final syncedProfile = UserProfile(
        id: backendData['id'] ?? existingProfile.id,
        fullName: backendData['full_name'] ?? existingProfile.fullName,
        age: backendData['age'] ?? existingProfile.age,
        gender: backendData['gender'] ?? existingProfile.gender,
        email: backendData['email'] ?? existingProfile.email,
        phoneNumber: backendData['phone'] ?? existingProfile.phoneNumber,
        profileImageUrl: backendData['profile_image_url'] ?? existingProfile.profileImageUrl,
        createdAt: backendData['created_at'] != null 
            ? DateTime.parse(backendData['created_at'])
            : existingProfile.createdAt,
        updatedAt: backendData['updated_at'] != null 
            ? DateTime.parse(backendData['updated_at'])
            : DateTime.now(),
      );
      
      await saveProfile(syncedProfile);
      return syncedProfile;
    } catch (e) {
      print('Sync failed: $e');
      return null;
    }
  }
}