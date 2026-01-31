import 'package:flutter/material.dart';
import '../profile_controller.dart';
import '../service/profile_service.dart';
import '../service/profile_cache_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../../../services/secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController _controller;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isEditing = false;
  String? _selectedGender;
  String? _userId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    try {
      // Get userId from SecureStorage
      _userId = await SecureStorage.getUserId();
      
      if (_userId == null) {
        setState(() {
          _errorMessage = 'User not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // Initialize services and controller
      final cacheService = ProfileCacheService();
      final profileService = ProfileService(cacheService);
      _controller = ProfileController(
        profileService: profileService,
      );
      
      // Initialize with fetch from backend
      _controller.initialize(_userId!, fetchFromBackend: true);
      _controller.addListener(_onProfileUpdated);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  void _onProfileUpdated() {
    if (mounted) {
      setState(() {
        if (!_isEditing && _controller.profile != null) {
          _nameController.text = _controller.profile!.fullName ?? '';
          _ageController.text = _controller.profile!.age?.toString() ?? '';
          _phoneController.text = _controller.profile!.phoneNumber ?? '';
          _selectedGender = _controller.profile!.gender;
        }
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _controller.profile != null) {
        _nameController.text = _controller.profile!.fullName ?? '';
        _ageController.text = _controller.profile!.age?.toString() ?? '';
        _phoneController.text = _controller.profile!.phoneNumber ?? '';
        _selectedGender = _controller.profile!.gender;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;
    
    try {
      await _controller.updateProfile(
        fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        age: _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _syncProfile() async {
    try {
      await _controller.syncProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _controller.clearProfile();
    // await SecureStorage.clearAll();
    
    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _controller.removeListener(_onProfileUpdated);
    _controller.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          if (_controller.isSyncing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _controller.isSyncing ? null : _syncProfile,
            tooltip: 'Sync with server',
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_userId != null) {
            await _controller.initialize(_userId!, fetchFromBackend: true);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProfileHeader(
                profile: _controller.profile,
                isLoading: _controller.isSaving,
                onEditPhoto: _isEditing ? () {
                  // TODO: Implement photo upload
                } : null,
              ),
              const SizedBox(height: 20),
              ProfileInfoCard(
                profile: _controller.profile,
                isEditing: _isEditing,
                onNameChanged: (value) {
                  _nameController.text = value ?? '';
                },
                onAgeChanged: (value) {
                  _ageController.text = value?.toString() ?? '';
                },
                onGenderChanged: (value) {
                  _selectedGender = value;
                },
                onPhoneChanged: (value) {
                  _phoneController.text = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              // Account Settings Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.email_outlined,
                        color: Colors.blue.shade600,
                      ),
                      title: const Text('Email'),
                      subtitle: Text(
                        _controller.profile?.email ?? 'Not set',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.blue.shade600,
                      ),
                      title: const Text('Member Since'),
                      subtitle: Text(
                        _controller.profile?.createdAt != null
                            ? '${_controller.profile!.createdAt!.day}/${_controller.profile!.createdAt!.month}/${_controller.profile!.createdAt!.year}'
                            : 'Not available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Action Buttons
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _controller.isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          child: _controller.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _toggleEditMode,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}