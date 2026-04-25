import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/app_snackbar.dart';
import '../profile_controller.dart';
import '../service/profile_service.dart';
import '../service/profile_cache_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../../../services/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _blue      = Color(0xFF1A73E8);
const _blueLight = Color(0xFFE8F0FE);
const _bgPage    = Color(0xFFF6F8FC);
const _surface   = Color(0xFFFFFFFF);
const _border    = Color(0xFFE8EAED);
const _textPri   = Color(0xFF1F1F1F);
const _textSec   = Color(0xFF5F6368);
const _red       = Color(0xFFD93025);
const _green     = Color(0xFF188038);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ══════════════════════════════════════════════════════════════════════════
  // STATE — untouched
  // ══════════════════════════════════════════════════════════════════════════
  late ProfileController _controller;
  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _ageController   = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool    _isEditing      = false;
  String? _selectedGender;
  String? _userId;
  bool    _isLoading      = true;
  String? _errorMessage;

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIC — untouched
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    try {
      _userId = await SecureStorage.getUserId();
      if (_userId == null) {
        setState(() {
          _errorMessage = 'User not found. Please login again.';
          _isLoading    = false;
        });
        return;
      }
      final cacheService  = ProfileCacheService();
      final profileService = ProfileService(cacheService);
      _controller = ProfileController(profileService: profileService);
      await _controller.initialize(_userId!, fetchFromBackend: false);
      _controller.addListener(_onProfileUpdated);
      setState(() => _isLoading = false);
      _controller.syncProfile(); // background sync — not repeated
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading    = false;
      });
    }
  }

  void _onProfileUpdated() {
    if (mounted) {
      setState(() {
        if (!_isEditing && _controller.profile != null) {
          _nameController.text  = _controller.profile!.fullName ?? '';
          _ageController.text   = _controller.profile!.age?.toString() ?? '';
          _phoneController.text = _controller.profile!.phoneNumber ?? '';
          _selectedGender       = _controller.profile!.gender;
        }
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _controller.profile != null) {
        _nameController.text  = _controller.profile!.fullName ?? '';
        _ageController.text   = _controller.profile!.age?.toString() ?? '';
        _phoneController.text = _controller.profile!.phoneNumber ?? '';
        _selectedGender       = _controller.profile!.gender;
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
      if (mounted) {
        _showSnack('Profile updated successfully!', _green);
        setState(() => _isEditing = false);
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to update profile', _red);
    }
  }

  Future<void> _syncProfile() async {
    try {
      await _controller.syncProfile();
      if (mounted) _showSnack('Profile synced!', _green);
    } catch (_) {
      if (mounted) _showSnack('Sync failed', _red);
    }
  }

  Future<void> _logout() async {
    await _controller.clearProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, 'login');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, size: 28, color: _red),
              ),
              const SizedBox(height: 16),
              const Text('Sign out?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPri)),
              const SizedBox(height: 8),
              const Text(
                'You will be signed out of your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textSec),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        foregroundColor: _textSec,
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        AppSnackbar.showSuccess(context, 'Signed out successfully');
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sign out',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        content: Row(children: [
          Icon(
            color == _green
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ]),
        duration: const Duration(seconds: 3),
      ));
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

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) return _buildLoader();
    // Error state
    if (_errorMessage != null) return _buildError();
    // Main screen
    return _buildMain();
  }

  // ── Full screen loader ────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_blue),
              ),
            ),
            SizedBox(height: 16),
            Text('Loading profile…',
                style: TextStyle(color: _textSec, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _appBar(showActions: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 48, color: _red),
              ),
              const SizedBox(height: 20),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPri)),
              const SizedBox(height: 8),
              const Text('Please login again to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _textSec)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, 'login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Login',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main profile screen ───────────────────────────────────────────────────
  Widget _buildMain() {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _appBar(showActions: true),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_userId != null) {
            await _controller.initialize(_userId!, fetchFromBackend: true);
          }
        },
        color: _blue,
        backgroundColor: _surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile header (white bg, clean circle) ───────────────
              ProfileHeader(
                profile: _controller.profile,
                isLoading: _controller.isSaving,
                onEditPhoto: _isEditing ? () {} : null,
              ),

              const SizedBox(height: 8),

              // ── Syncing indicator bar ─────────────────────────────────
              if (_controller.isSyncing)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: _blueLight,
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_blue),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Syncing with server…',
                          style: TextStyle(
                              fontSize: 12,
                              color: _blue,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ── Personal info card ─────────────────────────────────────
              ProfileInfoCard(
                profile: _controller.profile,
                isEditing: _isEditing,
                nameController: _nameController,
                ageController: _ageController,
                phoneController: _phoneController,
                onGenderChanged: (v) => _selectedGender = v,
              ),

              const SizedBox(height: 12),

              // ── Account details card ───────────────────────────────────
              _buildAccountCard(),

              const SizedBox(height: 20),

              // ── Edit action buttons ────────────────────────────────────
              if (_isEditing) _buildEditActions(),

              // ── Logout button ──────────────────────────────────────────
              if (!_isEditing) _buildLogoutButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar({required bool showActions}) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _surface,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: const Text(
        'Profile',
        style: TextStyle(
            color: _textPri,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _border),
      ),
      actions: showActions
          ? [
              // Sync spinner
              if (_controller.isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_blue),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync_rounded,
                      color: _textSec, size: 22),
                  onPressed: _syncProfile,
                  tooltip: 'Sync',
                ),
              // Edit / Done toggle
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: _textSec, size: 20),
                  onPressed: _toggleEditMode,
                  tooltip: 'Edit Profile',
                )
              else
                TextButton(
                  onPressed:
                      _controller.isSaving ? null : _saveProfile,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: _controller.isSaving
                          ? _textSec
                          : _blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ]
          : null,
    );
  }

  // ── Account details (email + member since) ────────────────────────────────
  Widget _buildAccountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _blue,
                  letterSpacing: 0.8),
            ),
          ),
          const Divider(height: 1, color: _border),
          _AccountRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _controller.profile?.email ?? '—',
          ),
          const Divider(height: 1, indent: 56, color: _border),
          _AccountRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _controller.profile?.createdAt != null
                ? '${_controller.profile!.createdAt!.day} / '
                    '${_controller.profile!.createdAt!.month} / '
                    '${_controller.profile!.createdAt!.year}'
                : '—',
          ),
        ],
      ),
    );
  }

  // ── Save / Cancel row ─────────────────────────────────────────────────────
  Widget _buildEditActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _controller.isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: _blue.withOpacity(0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _controller.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _toggleEditMode,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                foregroundColor: _textSec,
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showLogoutDialog,
          icon: Icon(Icons.logout_rounded, size: 18, color: _red),
          label: Text('Sign Out',
              style: TextStyle(
                  color: _red, fontWeight: FontWeight.w600, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: _red.withOpacity(0.3)),
            backgroundColor: _red.withOpacity(0.05),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

// ── Account row widget ────────────────────────────────────────────────────────
class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Icon(icon, size: 20, color: const Color(0xFF5F6368)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5F6368),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F1F1F),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}