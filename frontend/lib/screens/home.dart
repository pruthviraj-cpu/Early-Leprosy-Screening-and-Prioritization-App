import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  String? gender;
  String? symptoms;
  String? location;

  File? selectedImage;
  bool loading = false;
  Map<String, dynamic>? predictionResult;

  final ImagePicker _picker = ImagePicker();

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> symptomsList = ['Skin patches', 'Numbness', 'Lesions'];
  final List<String> locations = ['Hand', 'Leg', 'Face'];

  /* ---------- IMAGE PICK ---------- */
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        predictionResult = null;
      });
    }
  }

  /* ---------- CLASSIFY ---------- */
  Future<void> classifyImage() async {
    if (selectedImage == null) return;
    setState(() => loading = true);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://tes112t-leprosy.hf.space/predict'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', selectedImage!.path),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      setState(() {
        predictionResult = Map<String, dynamic>.from(jsonResponse);
        loading = false;
      });
    } catch (e) {
      setState(() {
        predictionResult = {
          'error': 'Failed to process image',
          'score': 0.0,
          'decision': 'ERROR',
        };
        loading = false;
      });
    }
  }

  /* ---------- Diagnosis Save ---------- */
  Future<void> saveDiagnosis() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await SecureStorage.getToken();
    print(token);

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again")),
      );
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    final body = {
      "flul_name": nameCtrl.text,
      "age": int.parse(ageCtrl.text),
      "gender": gender,
      "number": phoneCtrl.text,
      "symptoms": symptoms,
      "affected_area": location,
      "probability": predictionResult != null
          ? (predictionResult!['score'] ?? 0.0)
          : null,
      "image_url": predictionResult != null
          ? (predictionResult!['filename'] ?? '')
          : '',
      "latitude": 0.0,
      "longitude": 0.0,
    };

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/diagnosis/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ REAL TOKEN
      },
      body: jsonEncode(body),
    );

    // snackbar logic stays same
    // Show a more professional snackbar
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: response.statusCode == 200
            ? const Color(0xff10B981)
            : const Color(0xffEF4444),
        content: Row(
          children: [
            Icon(
              response.statusCode == 200 ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                response.statusCode == 200
                    ? 'Profile updated successfully'
                    : 'Profile update failed',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Skin Health Assessment",
          style: TextStyle(
            color: Color(0xff0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xff0F172A)),
        actions: [
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
                  Icons.logout,
                  color: Color(0xffEF4444),
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, 'login');
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xffE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Basic Details Card
            _buildSectionCard(
              title: "Basic Details",
              icon: Icons.person_outline,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField(nameCtrl, "Full Name", Icons.person),
                    const SizedBox(height: 16),
                    _buildInputField(
                      ageCtrl,
                      "Age",
                      Icons.calendar_today,
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      "Gender",
                      genders,
                      gender,
                      Icons.transgender,
                      (v) => setState(() => gender = v),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(phoneCtrl, "Phone Number", Icons.phone),
                    const SizedBox(height: 24),
                    // _buildPrimaryButton("Save Profile", updateProfile),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Symptoms & Location Card
            _buildSectionCard(
              title: "Symptoms & Location",
              icon: Icons.medical_services_outlined,
              child: Column(
                children: [
                  _buildDropdown(
                    "Symptoms",
                    symptomsList,
                    symptoms,
                    Icons.health_and_safety,
                    (v) => setState(() => symptoms = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    "Affected Area",
                    locations,
                    location,
                    Icons.location_on_outlined,
                    (v) => setState(() => location = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Image Classification Card
            _buildSectionCard(
              title: "Image Analysis",
              icon: Icons.image_outlined,
              child: Column(
                children: [
                  // Image Preview
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xffF1F5F9),
                      border: Border.all(
                        color: const Color(0xffE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Selected',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: Color(0xff94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Upload an image',
                                style: TextStyle(
                                  color: const Color(0xff64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Supports JPG, PNG',
                                style: TextStyle(
                                  color: const Color(0xff94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          "Upload Image",
                          pickImage,
                          icon: Icons.upload_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrimaryButton(
                          "Analyze",
                          classifyImage,
                          icon: Icons.search_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPrimaryButton(
                          "Save Diagnosis",
                          saveDiagnosis,
                          icon: Icons.save_outlined,
                        ),
                      ),
                    ],
                  ),

                  // Loading Indicator
                  if (loading) ...[
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff0EA5A4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Analyzing image...',
                          style: TextStyle(
                            color: Color(0xff64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Prediction Result
                  if (predictionResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getResultColor(predictionResult!['decision']),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getResultIcon(predictionResult!['decision']),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  predictionResult!['decision'] ?? 'UNKNOWN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Confidence Score
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confidence Score',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value:
                                            (predictionResult!['score'] ?? 0.0)
                                                .toDouble(),
                                        backgroundColor: Colors.white24,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _getScoreColor(
                                                (predictionResult!['score'] ??
                                                        0.0)
                                                    .toDouble(),
                                              ),
                                            ),
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${((predictionResult!['score'] ?? 0.0).toDouble() * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (predictionResult!['filename'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'File: ${predictionResult!['filename']}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Additional Info
                          if (predictionResult!['error'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                predictionResult!['error'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /* ---------- REUSABLE WIDGETS ---------- */

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xffF1F5F9), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xff0EA5A4), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Card Content
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xff0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xff94A3B8),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff0EA5A4), width: 1.5),
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xff64748B)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    IconData icon,
    Function(String?) onChange,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0F172A),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChange,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xff0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xff94A3B8),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff0EA5A4), width: 1.5),
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xff64748B)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xff64748B)),
    );
  }

  Widget _buildPrimaryButton(
    String text,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0EA5A4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
    String text,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xffE2E8F0), width: 1),
        foregroundColor: const Color(0xff64748B),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /* ---------- HELPER FUNCTIONS ---------- */

  Color _getResultColor(String decision) {
    switch (decision.toUpperCase()) {
      case 'LEPROSY':
        return const Color(0xffEF4444);
      case 'HEALTHY':
        return const Color(0xff10B981);
      default:
        return const Color(0xff64748B);
    }
  }

  IconData _getResultIcon(String decision) {
    switch (decision.toUpperCase()) {
      case 'LEPROSY':
        return Icons.warning_amber_outlined;
      case 'HEALTHY':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getScoreColor(double score) {
    if (score > 0.7) return const Color(0xff10B981);
    if (score > 0.4) return const Color(0xffF59E0B);
    return const Color(0xffEF4444);
  }
}
