import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/utils/app_snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../screens/patient_list.dart';
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Session expired. Please login again")),
      // );
      AppSnackbar.showError(context, "Session expired. Please login again");
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("https://skin-buddy.onrender.com/api/diagnosis/patients/all"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          _patients = data["data"];
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load patients.";
          _loading = false;
        });
      }
    } catch (e) {
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
        child: Text(_error!, style: const TextStyle(color: Color(0xffEF4444))),
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
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "doctor_details",
                  arguments: _patients[index],
                );
              },
            );
          },
        );
      },
    );
  }
}
