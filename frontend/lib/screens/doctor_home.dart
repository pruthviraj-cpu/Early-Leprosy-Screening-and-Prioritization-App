import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/secure_storage.dart';

class DoctorHomePage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorHomePage({super.key, required this.patient});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool loading = false;
  late Map<String, dynamic> patient;

  @override
  void initState() {
    super.initState();
    patient = Map.from(widget.patient); // Create a mutable copy
    print("IMAGE URL: ${patient["image_url"]}");
    print("DOCTOR REVIEW: ${patient["doctor_review"]}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: loading 
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff0EA5A4)),
              ),
            )
          : const Text(
              "Patient Diagnosis Review",
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Return the updated patient data when back button is pressed
            Navigator.pop(context, patient);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionCard(
              title: "Patient Information",
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _buildInfoRow("Name", patient["full_name"]),
                  _buildInfoRow("Age", patient["age"]),
                  _buildInfoRow("Gender", patient["gender"]),
                  _buildInfoRow("Phone", patient["phone"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Symptoms & Area",
              icon: Icons.medical_services_outlined,
              child: Column(
                children: [
                  _buildInfoRow("Symptoms", patient["symptoms"]),
                  _buildInfoRow("Affected Area", patient["affected_area"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Patient Image",
              icon: Icons.image_outlined,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      insetPadding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: patient["image_url"] != null
                                  ? Image.network(
                                      patient["image_url"],
                                      fit: BoxFit.contain,
                                    )
                                  : const SizedBox(),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: patient["image_url"] != null
                      ? Image.network(
                          patient["image_url"],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 220,
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildResultCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final decision = patient["diagnosis_result"] ?? "Pending";
    final score = (patient["probability"] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getResultColor(decision),
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
                  _getResultIcon(decision),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  decision,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(score),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(score * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Doctor Review Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Doctor Review",
                  style: TextStyle(
                    color: Color(0xff0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriorityButton(
                        label: "High",
                        color: Colors.red,
                        selected: patient["doctor_review"] == "high",
                        onTap: () => _updateDoctorReview("high"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityButton(
                        label: "Medium",
                        color: Colors.orange,
                        selected: patient["doctor_review"] == "medium",
                        onTap: () => _updateDoctorReview("medium"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPriorityButton(
                        label: "Low",
                        color: Colors.green,
                        selected: patient["doctor_review"] == "low",
                        onTap: () => _updateDoctorReview("low"),
                      ),
                    ),
                  ],
                ),
                if (patient["doctor_review"] != null && patient["doctor_review"].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(patient["doctor_review"]).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _getStatusColor(patient["doctor_review"]),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Current Review: ${_getStatusText(patient["doctor_review"])}",
                            style: TextStyle(
                              color: _getStatusColor(patient["doctor_review"]),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? review) {
    if (review == null || review.isEmpty) return "Pending Review";
    switch (review.toLowerCase()) {
      case 'high': return "High Priority";
      case 'medium': return "Medium Priority";
      case 'low': return "Low Priority";
      default: return "Reviewed";
    }
  }

  Color _getStatusColor(String? review) {
    if (review == null || review.isEmpty) return const Color(0xff94A3B8);
    switch (review.toLowerCase()) {
      case 'high': return const Color(0xffEF4444);
      case 'medium': return const Color(0xffF59E0B);
      case 'low': return const Color(0xff10B981);
      default: return const Color(0xff10B981);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
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
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "Not Provided",
              style: const TextStyle(
                color: Color(0xff0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _updateDoctorReview(String priority) async {
    setState(() {
      loading = true;
    });

    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired. Please login again"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, 'login');
        return;
      }

      print("Updating review for diagnosis ID: ${patient['id']} with priority: $priority");

      final response = await http.put(
        Uri.parse("https://skin-buddy.onrender.com/api/diagnosis/${patient['id']}/review"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          'doctor_review': priority,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        // Update local state with the new review
        setState(() {
          patient["doctor_review"] = priority;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Review updated to $priority priority"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Small delay to show the success message before navigating back
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Return the updated patient data and pop
        Navigator.pop(context, patient);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Failed to update review"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        setState(() {
          loading = false;
        });
      }
    } catch (error) {
      print("Error updating review: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating review: $error"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() {
        loading = false;
      });
    }
  }

  Color _getResultColor(String decision) {
    switch (decision.toUpperCase()) {
      case 'LEPROSY':
        return const Color(0xffEF4444);
      case 'NOT LEPROSY':
        return const Color(0xff10B981);
      default:
        return const Color(0xff10B981);
    }
  }

  IconData _getResultIcon(String decision) {
    switch (decision.toUpperCase()) {
      case 'LEPROSY':
        return Icons.warning_amber_outlined;
      case 'NOT LEPROSY':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getScoreColor(double score) {
    if (score > 0.7) return const Color(0xff10B981);
    if (score > 0.4) return const Color(0xffF59E0B);
    return Colors.white;
  }
}