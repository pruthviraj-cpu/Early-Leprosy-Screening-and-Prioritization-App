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
      _controller = ProfileController(profileService: profileService);

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
        fullName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        age: _ageController.text.trim().isEmpty
            ? null
            : int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Show success message with professional snackbar
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xff10B981),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profile updated successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xffEF4444),
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to update profile',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  void _syncProfile() async {
    try {
      await _controller.syncProfile();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xff10B981),
              content: Row(
                children: [
                  const Icon(Icons.sync, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profile synced successfully!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xffEF4444),
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sync failed',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffFEE2E2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.logout,
                  size: 32,
                  color: Color(0xffEF4444),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xff64748B)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xffE2E8F0)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      return Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Center(
          child: Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0F172A).withOpacity(0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff0EA5A4)),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Color(0xff0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xff0F172A)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xffE2E8F0)),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF2F2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xffEF4444),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xff0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please login again to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xff64748B)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0EA5A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xff0F172A)),
        actions: [
          // Sync indicator
          if (_controller.isSyncing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xff0EA5A4),
                    ),
                  ),
                ),
              ),
            ),
          // Sync button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sync_outlined,
                  color: Color(0xff64748B),
                  size: 20,
                ),
              ),
              onPressed: _controller.isSyncing ? null : _syncProfile,
              tooltip: 'Sync with server',
            ),
          ),
          // Edit button
          // removed button of edit
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xff64748B),
                    size: 20,
                  ),
                ),
                onPressed: _toggleEditMode,
                tooltip: 'Edit Profile',
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xffE2E8F0)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_userId != null) {
            await _controller.initialize(_userId!, fetchFromBackend: true);
          }
        },
        color: const Color(0xff0EA5A4),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProfileHeader(
                profile: _controller.profile,
                isLoading: _controller.isSaving,
                onEditPhoto: _isEditing
                    ? () {
                        // TODO: Implement photo upload
                      }
                    : null,
              ),
              const SizedBox(height: 20),
              // !Changes for name updation
              ProfileInfoCard(
                profile: _controller.profile,
                isEditing: _isEditing,
                nameController: _nameController,
                ageController: _ageController,
                phoneController: _phoneController,
                onGenderChanged: (value) {
                  _selectedGender = value;
                },
              ),
              const SizedBox(height: 20),
              // Account Settings Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff0F172A).withOpacity(0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Color(0xff0EA5A4),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff64748B),
                        ),
                      ),
                      subtitle: Text(
                        _controller.profile?.email ?? 'Not set',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 20),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xff0EA5A4),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Member Since',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff64748B),
                        ),
                      ),
                      subtitle: Text(
                        _controller.profile?.createdAt != null
                            ? '${_controller.profile!.createdAt!.day}/${_controller.profile!.createdAt!.month}/${_controller.profile!.createdAt!.year}'
                            : 'Not available',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Action Buttons
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _controller.isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0EA5A4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff64748B),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showLogoutDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xffFEE2E2)),
                      backgroundColor: const Color(0xffFEF2F2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          size: 20,
                          color: const Color(0xffEF4444),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xffEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
