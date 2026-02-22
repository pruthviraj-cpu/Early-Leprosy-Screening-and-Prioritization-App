import 'package:flutter/material.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  bool loading = false;

  // 🔹 Sample backend data (replace with API call later)
  final Map<String, dynamic> diagnosis = {
    "full_name": "Rahul Sharma",
    "age": 32,
    "gender": "Male",
    "phone": "9876543210",
    "symptoms": "Skin patches",
    "affected_area": "Hand",
    "probability": 0.82,
    "decision": "LEPROSY",
    "image_url":
        "data:image/jpeg;base64,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",
  };

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
        // iconTheme: const IconThemeData(color: Color(0xff0F172A)),
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
                  _buildInfoRow("Name", diagnosis["full_name"]),
                  _buildInfoRow("Age", diagnosis["age"].toString()),
                  _buildInfoRow("Gender", diagnosis["gender"]),
                  _buildInfoRow("Phone", diagnosis["phone"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Symptoms & Area",
              icon: Icons.medical_services_outlined,
              child: Column(
                children: [
                  _buildInfoRow("Symptoms", diagnosis["symptoms"]),
                  _buildInfoRow("Affected Area", diagnosis["affected_area"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Patient Image",
              icon: Icons.image_outlined,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  diagnosis["image_url"],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
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
    final decision = diagnosis["decision"];
    final score = diagnosis["probability"];

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

  Widget _buildInfoRow(String label, String value) {
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
              value,
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
