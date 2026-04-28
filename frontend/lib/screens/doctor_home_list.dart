import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/utils/app_snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/patient_list.dart';
import 'package:frontend/services/secure_storage.dart';
import 'package:frontend/screens/filter_chip_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DoctorHomeListPage extends StatefulWidget {
  const DoctorHomeListPage({super.key});

  @override
  State<DoctorHomeListPage> createState() => _DoctorHomeListPageState();
}

class _DoctorHomeListPageState extends State<DoctorHomeListPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _allPatients = [];
  List<dynamic> _filteredPatients = [];

  // Filter states
  String? _selectedReviewFilter;
  String? _selectedDiagnosisFilter;
  String _searchQuery = '';

  // Animation controller for filter panel
  late AnimationController _animationController;
  bool _isFilterExpanded = false;

  // Filter options
  final List<Map<String, dynamic>> _reviewFilters = [
    {'value': null, 'label': 'All', 'icon': Icons.list},
    {
      'value': 'pending',
      'label': 'Pending Review',
      'icon': Icons.pending_outlined,
      'color': Colors.grey,
    },
    {
      'value': 'high',
      'label': 'High Priority',
      'icon': Icons.priority_high,
      'color': Colors.red,
    },
    {
      'value': 'medium',
      'label': 'Medium Priority',
      'icon': Icons.remove,
      'color': Colors.orange,
    },
    {
      'value': 'low',
      'label': 'Low Priority',
      'icon': Icons.low_priority,
      'color': Colors.green,
    },
  ];

  final List<Map<String, dynamic>> _diagnosisFilters = [
    {'value': null, 'label': 'All Results', 'icon': Icons.medical_services},
    {
      'value': 'LEPROSY',
      'label': 'Leprosy',
      'icon': Icons.warning,
      'color': Colors.red,
    },
    {
      'value': 'NOT LEPROSY',
      'label': 'Not Leprosy',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    requestPermission();
    getToken();
    setupForegroundListener();
    _fetchPatients();
  }

  void requestPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();

    print('Permission: ${settings.authorizationStatus}');
  }

  void getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();

    print("DEVICE TOKEN: $token");
  }

  void setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        "Notification received (foreground): ${message.notification?.title}",
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      AppSnackbar.showError(context, "Session expired. Please login again");
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

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

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          _allPatients = data["data"] ?? [];
          _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        // Apply review filter
        if (_selectedReviewFilter != null) {
          if (_selectedReviewFilter == 'pending') {
            if (patient["doctor_review"] != null &&
                patient["doctor_review"].toString().isNotEmpty) {
              return false;
            }
          } else {
            if (patient["doctor_review"] != _selectedReviewFilter) {
              return false;
            }
          }
        }

        // Apply diagnosis filter
        if (_selectedDiagnosisFilter != null &&
            patient["diagnosis_result"] != _selectedDiagnosisFilter) {
          return false;
        }

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final name = patient["full_name"]?.toString().toLowerCase() ?? '';
          final symptoms = patient["symptoms"]?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();

          if (!name.contains(query) && !symptoms.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedReviewFilter = null;
      _selectedDiagnosisFilter = null;
      _searchQuery = '';
      _filteredPatients = _allPatients;
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedReviewFilter != null) count++;
    if (_selectedDiagnosisFilter != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
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
          // Filter count badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
                    if (_isFilterExpanded) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  });
                },
              ),
              if (_getActiveFilterCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xff0EA5A4),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(12),
          //       boxShadow: [
          //         BoxShadow(
          //           color: const Color(0xff0F172A).withOpacity(0.04),
          //           blurRadius: 10,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: TextField(
          //       onChanged: (value) {
          //         _searchQuery = value;
          //         _applyFilters();
          //       },
          //       decoration: InputDecoration(
          //         hintText: 'Search by name or symptoms...',
          //         hintStyle: const TextStyle(color: Color(0xff94A3B8)),
          //         prefixIcon: const Icon(Icons.search, color: Color(0xff64748B)),
          //         suffixIcon: _searchQuery.isNotEmpty
          //             ? IconButton(
          //                 icon: const Icon(Icons.clear, color: Color(0xff64748B)),
          //                 onPressed: () {
          //                   _searchQuery = '';
          //                   _applyFilters();
          //                 },
          //               )
          //             : null,
          //         border: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(12),
          //           borderSide: BorderSide.none,
          //         ),
          //         filled: true,
          //         fillColor: Colors.white,
          //         contentPadding: const EdgeInsets.symmetric(vertical: 12),
          //       ),
          //     ),
          //   ),
          // ),

          // Filter Chips Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isFilterExpanded ? null : 0,
            child: _isFilterExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Review Status Filters
                        const Text(
                          'Review Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _reviewFilters.map((filter) {
                            return FilterChipWidget(
                              label: filter['label'],
                              icon: filter['icon'],
                              color: filter['color'] ?? const Color(0xff0EA5A4),
                              isSelected:
                                  _selectedReviewFilter == filter['value'],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedReviewFilter = selected
                                      ? filter['value']
                                      : null;
                                  _applyFilters();
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Diagnosis Result Filters
                        const Text(
                          'Diagnosis Result',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _diagnosisFilters.map((filter) {
                            return FilterChipWidget(
                              label: filter['label'],
                              icon: filter['icon'],
                              color: filter['color'] ?? const Color(0xff0EA5A4),
                              isSelected:
                                  _selectedDiagnosisFilter == filter['value'],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDiagnosisFilter = selected
                                      ? filter['value']
                                      : null;
                                  _applyFilters();
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Clear Filters Button
                        if (_getActiveFilterCount() > 0)
                          Center(
                            child: TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear All Filters'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xffEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPatients.length} patients found',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_filteredPatients.isEmpty && !_loading)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Clear filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xff0EA5A4),
                    ),
                  ),
              ],
            ),
          ),

          // Patient List
          Expanded(child: _buildBody()),
        ],
      ),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xffEF4444))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPatients,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0EA5A4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedReviewFilter != null ||
                      _selectedDiagnosisFilter != null
                  ? "No patients match your filters"
                  : "No patient diagnoses available.",
              style: const TextStyle(color: Color(0xff64748B), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your search or filters",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredPatients.length,
          itemBuilder: (context, index) {
            return PatientListItem(
              patient: _filteredPatients[index],
              isDesktop: isDesktop,
              onTap: () async {
                // Navigate to details and wait for result
                final updatedPatient = await Navigator.pushNamed(
                  context,
                  "doctor_details",
                  arguments: _filteredPatients[index],
                );

                // If we got updated data back, update the list
                if (updatedPatient != null &&
                    updatedPatient is Map<String, dynamic>) {
                  print(
                    "Received updated patient with review: ${updatedPatient['doctor_review']}",
                  );

                  // Update in all patients list
                  final allIndex = _allPatients.indexWhere(
                    (p) => p['id'] == updatedPatient['id'],
                  );
                  if (allIndex != -1) {
                    _allPatients[allIndex] = updatedPatient;
                  }

                  // Re-apply filters to update filtered list
                  _applyFilters();
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
