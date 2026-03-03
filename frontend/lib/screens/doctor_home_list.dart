import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/utils/app_snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/patient_list.dart';
import 'package:frontend/services/secure_storage.dart';

class DoctorHomeListPage extends StatefulWidget {
  const DoctorHomeListPage({super.key});

  @override
  State<DoctorHomeListPage> createState() => _DoctorHomeListPageState();
}

class _DoctorHomeListPageState extends State<DoctorHomeListPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      AppSnackbar.showError(context, "Session expired. Please login again");
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    try {
      print("Fetching patients...");
      final response = await http.get(
        Uri.parse("https://skin-buddy.onrender.com/api/diagnosis/patients/all"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Response status: ${response.statusCode}");
      final data = jsonDecode(response.body);
      print("Data received: ${data.containsKey('data') ? data['data'].length : 0} patients");

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          _patients = data["data"] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load patients.";
          _loading = false;
        });
      }
    } catch (e) {
      print("Error fetching patients: $e");
      setState(() {
        _error = "Network error. Please try again.";
        _loading = false;
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xffEF4444))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPatients,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
      return const Center(
        child: Text(
          "No patient diagnoses available.",
          style: TextStyle(color: Color(0xff64748B)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _patients.length,
          itemBuilder: (context, index) {
            return PatientListItem(
              patient: _patients[index],
              isDesktop: isDesktop,
              onTap: () async {
                // Navigate to details and wait for result
                final updatedPatient = await Navigator.pushNamed(
                  context,
                  "doctor_details",
                  arguments: _patients[index],
                );
                
                // If we got updated data back, refresh the list
                if (updatedPatient != null && updatedPatient is Map<String, dynamic>) {
                  print("Received updated patient with review: ${updatedPatient['doctor_review']}");
                  // Update the specific patient in the list
                  setState(() {
                    final index = _patients.indexWhere((p) => p['id'] == updatedPatient['id']);
                    if (index != -1) {
                      _patients[index] = updatedPatient;
                    }
                  });
                } else {
                  // If no data returned, refresh the whole list
                  _fetchPatients();
                }
              },
            );
          },
        );
      },
    );
  }
}