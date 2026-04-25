import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../models/pending_diagnosis.dart';
import '../services/diagnosis_cache_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg            = Color(0xFFF6F8FC);
const _surface       = Color(0xFFFFFFFF);
const _teal          = Color(0xFF1A73E8);
const _tealLight     = Color(0xFFE8F0FE);
const _tealDark      = Color(0xFF1557B0);
const _textPrimary   = Color(0xFF1F1F1F);
const _textSecondary = Color(0xFF5F6368);
const _textHint      = Color(0xFF9AA0A6);
const _border        = Color(0xFFE8EAED);
const _borderFocus   = Color(0xFF1A73E8);
const _red           = Color(0xFFD93025);
const _green         = Color(0xFF188038);
const _fillColor     = Color(0xFFF8F9FA);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl  = TextEditingController();
  final TextEditingController ageCtrl   = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  String? gender;
  String? symptoms;
  String? location;

  File?  selectedImage;
  bool   loading    = false;
  bool   _isSyncing = false;

  late final StreamSubscription<ConnectivityResult> _connectivitySub;
  final ImagePicker _picker = ImagePicker();

  final List<String> genders      = ['Male', 'Female', 'Other'];
  final List<String> symptomsList = ['Skin patches', 'Numbness', 'Lesions'];
  final List<String> locations    = ['Hand', 'Leg', 'Face'];

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _listenToInternet();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    nameCtrl.dispose();
    ageCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONNECTIVITY — same pattern as chat screen
  // ══════════════════════════════════════════════════════════════════════════

  void _listenToInternet() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncPendingForms();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SYNC PENDING FORMS (runs when internet comes back)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _syncPendingForms() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = DiagnosisCacheService.getPending();
      if (pending.isEmpty) return;

      final token = await SecureStorage.getToken();
      if (token == null) return;

      for (final entry in pending) {
        try {
          // Mark as sending to prevent duplicate sends
          entry.syncStatus = 'sending';
          await DiagnosisCacheService.save(entry);

          final imageFile = File(entry.imagePath);
          if (!await imageFile.exists()) {
            // Image was deleted from device — skip silently
            entry.syncStatus = 'failed';
            await DiagnosisCacheService.save(entry);
            continue;
          }

          // Get fresh location for offline submissions
          Position position;
          try {
            position = await getCurrentLocation();
          } catch (_) {
            // If location fails during sync, fall back to 0,0
            position = Position(
              latitude: 0,
              longitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }

          var request = http.MultipartRequest(
            'POST',
            Uri.parse('https://skin-buddy.onrender.com/api/diagnosis/create'),
          );

          request.headers['Authorization'] = 'Bearer $token';
          request.fields['full_name']     = entry.fullName;
          request.fields['age']           = entry.age;
          request.fields['gender']        = entry.gender;
          request.fields['number']        = entry.phone;
          request.fields['symptoms']      = entry.symptoms;
          request.fields['affected_area'] = entry.affectedArea;
          request.fields['latitude']      = position.latitude.toString();
          request.fields['longitude']     = position.longitude.toString();
          request.files.add(
            await http.MultipartFile.fromPath('file', entry.imagePath),
          );

          final streamed  = await request.send();
          final response  = await http.Response.fromStream(streamed);
          final data      = jsonDecode(response.body);

          if (response.statusCode == 200 && data['success'] == true) {
            entry.syncStatus = 'synced';
            await DiagnosisCacheService.save(entry);
            if (mounted) {
              _showSnack('Offline diagnosis synced successfully!', _green,
                  subtitle: 'Your saved form was sent.');
            }
          } else {
            entry.syncStatus = 'pending'; // retry next time
            await DiagnosisCacheService.save(entry);
          }
        } catch (e) {
          debugPrint('Sync error for ${entry.id}: $e');
          entry.syncStatus = 'pending';
          await DiagnosisCacheService.save(entry);
        }
      }

      // Clean up synced records
      await DiagnosisCacheService.deleteSynced();
    } catch (e) {
      debugPrint('_syncPendingForms error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IMAGE PICK — untouched
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => selectedImage = File(image.path));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCATION — untouched
  // ══════════════════════════════════════════════════════════════════════════

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever)
      throw Exception(
          'Location permissions are permanently denied, cannot request.');

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUBMIT — saves to Hive first, then tries network (same as chat)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> submitDiagnosis() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedImage == null) {
      _showSnack('Please select an image first', _red);
      return;
    }

    setState(() => loading = true);

    final token = await SecureStorage.getToken();
    if (token == null) {
      setState(() => loading = false);
      _showSnack('Session expired. Please login again', _red);
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    // ── 1️⃣  Save to Hive immediately (offline-first) ─────────────────────
    final entry = PendingDiagnosis(
      id:           '${DateTime.now().millisecondsSinceEpoch}_diag',
      fullName:     nameCtrl.text.trim(),
      age:          ageCtrl.text.trim(),
      gender:       gender ?? '',
      phone:        phoneCtrl.text.trim(),
      symptoms:     symptoms ?? '',
      affectedArea: location ?? '',
      imagePath:    selectedImage!.path,
      syncStatus:   'pending',
      createdAt:    DateTime.now(),
    );
    await DiagnosisCacheService.save(entry);

    // ── 2️⃣  Check connectivity ────────────────────────────────────────────
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet  = connectivity != ConnectivityResult.none;

    if (hasInternet) {
      // Send right now
      await _sendToBackend(entry, token);
    } else {
      // Save locally, will sync when internet returns (like chat offline mode)
      setState(() => loading = false);
      _showSnack(
        'Saved offline. Will submit when connected.',
        const Color(0xFFF9AB00),
        subtitle: 'Your form is safely stored on this device.',
      );
      _clearForm();
    }
  }

  // ── Send one entry to backend ──────────────────────────────────────────────
  Future<void> _sendToBackend(PendingDiagnosis entry, String token) async {
    try {
      entry.syncStatus = 'sending';
      await DiagnosisCacheService.save(entry);

      Position position = await getCurrentLocation();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://skin-buddy.onrender.com/api/diagnosis/create'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['full_name']     = entry.fullName;
      request.fields['age']           = entry.age;
      request.fields['gender']        = entry.gender;
      request.fields['number']        = entry.phone;
      request.fields['symptoms']      = entry.symptoms;
      request.fields['affected_area'] = entry.affectedArea;
      request.fields['latitude']      = position.latitude.toString();
      request.fields['longitude']     = position.longitude.toString();
      request.files.add(
        await http.MultipartFile.fromPath('file', entry.imagePath),
      );

      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);
      final data      = jsonDecode(response.body);

      setState(() => loading = false);
      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode == 200 && data['success'] == true) {
        entry.syncStatus = 'synced';
        await DiagnosisCacheService.save(entry);
        await DiagnosisCacheService.deleteSynced();

        _showSnack('Diagnosis submitted successfully!', _green,
            subtitle: 'Your report has been recorded.');
        _clearForm();
      } else {
        // Mark pending so sync retries it
        entry.syncStatus = 'pending';
        await DiagnosisCacheService.save(entry);

        _showSnack(data['message'] ?? 'Failed to save diagnosis', _red);
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('_sendToBackend error: $e');

      // Keep as pending — will retry on reconnect
      entry.syncStatus = 'pending';
      await DiagnosisCacheService.save(entry);

      if (mounted) {
        setState(() => loading = false);
        _showSnack(
          'No connection. Form saved locally.',
          const Color(0xFFF9AB00),
          subtitle: 'Will submit automatically when online.',
        );
        _clearForm();
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS — untouched
  // ══════════════════════════════════════════════════════════════════════════

  void _clearForm() {
    nameCtrl.clear();
    ageCtrl.clear();
    phoneCtrl.clear();
    setState(() {
      gender        = null;
      symptoms      = null;
      location      = null;
      selectedImage = null;
    });
  }

  void _showSnack(String message, Color color, {String? subtitle}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: color,
        elevation: 4,
        content: Row(
          children: [
            Icon(
              color == _green
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11)),
                  ],
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD — 100% identical to before, zero UI change
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _StepCard(
                          step: 1,
                          title: 'Personal Details',
                          subtitle: 'Tell us about yourself',
                          child: _buildPersonalSection(),
                        ),
                        const SizedBox(height: 16),
                        _StepCard(
                          step: 2,
                          title: 'Symptoms & Area',
                          subtitle: 'Describe what you are experiencing',
                          child: _buildSymptomsSection(),
                        ),
                        const SizedBox(height: 16),
                        _StepCard(
                          step: 3,
                          title: 'Upload Photo',
                          subtitle: 'Clear photo of the affected area',
                          child: _buildImageSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSubmitBar(),
          ),
          if (loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 69, 135, 221),
                Color.fromARGB(255, 46, 114, 203),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medical_information_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Skin Assessment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      children: [
        _Field(
          controller: nameCtrl,
          hint: 'Full Name',
          icon: Icons.person_outline_rounded,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Field(
                controller: ageCtrl,
                hint: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                hint: 'Gender',
                icon: Icons.wc_outlined,
                items: genders,
                value: gender,
                onChanged: (v) => setState(() => gender = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Field(
          controller: phoneCtrl,
          hint: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildSymptomsSection() {
    return Column(
      children: [
        _DropdownField(
          hint: 'Select Symptoms',
          icon: Icons.health_and_safety_outlined,
          items: symptomsList,
          value: symptoms,
          onChanged: (v) => setState(() => symptoms = v),
        ),
        const SizedBox(height: 14),
        _DropdownField(
          hint: 'Affected Area',
          icon: Icons.location_on_outlined,
          items: locations,
          value: location,
          onChanged: (v) => setState(() => location = v),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selectedImage != null ? Colors.transparent : _fillColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedImage != null
                    ? const Color.fromARGB(255, 118, 166, 227)
                    : _border,
                width: selectedImage != null ? 2 : 1.5,
              ),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(selectedImage!, fit: BoxFit.cover),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  'Photo selected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Change',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: _tealLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Color.fromARGB(255, 112, 163, 230)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tap to upload photo',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'JPG or PNG  •  High quality preferred',
                        style: TextStyle(color: _textHint, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : submitDiagnosis,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 113, 164, 231),
            disabledBackgroundColor:
                const Color.fromARGB(255, 106, 161, 232).withOpacity(0.5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.send_rounded, size: 18),
              SizedBox(width: 10),
              Text(
                'Submit Diagnosis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 48),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 115, 163, 226),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Analyzing...',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Please wait a moment',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Step Card ─────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Reusable Text Field ───────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 14,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 14),
        filled: true,
        fillColor: _fillColor,
        prefixIcon: Icon(icon, size: 18, color: _textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 108, 158, 223), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Reusable Dropdown Field ───────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _DropdownField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: _surface,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _textSecondary, size: 20),
      style: const TextStyle(
        fontSize: 14,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 14),
        filled: true,
        fillColor: _fillColor,
        prefixIcon: Icon(icon, size: 18, color: _textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 83, 141, 218), width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(fontSize: 14, color: _textPrimary)),
              ))
          .toList(),
    );
  }
}