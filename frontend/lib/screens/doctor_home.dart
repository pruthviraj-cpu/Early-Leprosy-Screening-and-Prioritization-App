import 'package:flutter/material.dart';
import 'dart:convert';

class DoctorHomePage extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorHomePage({super.key, required this.patient});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool loading = false;


  late Map<String, dynamic> patient;
  late Map<String, dynamic> diagnosis;

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
    print("IMAGE URL: ${patient["image_url"]}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
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
                    : const SizedBox(),
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

  /* ---------- RESULT CARD ---------- */

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
        ],
      ),
    );
  }

  /* ---------- SECTION CARD ---------- */

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

  /* ---------- COLORS ---------- */

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
      case 'HEALTHY':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getScoreColor(double score) {
    if (score > 0.7) return const Color(0xff10B981);
    if (score > 0.4) return const Color(0xffF59E0B);
    return const Color.fromARGB(255, 255, 255, 255);
  }
}
