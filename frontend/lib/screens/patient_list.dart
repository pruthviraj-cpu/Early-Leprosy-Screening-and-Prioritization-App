import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientListItem extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  final bool isDesktop;

  const PatientListItem({
    super.key,
    required this.patient,
    required this.onTap,
    required this.isDesktop,
  });

  String _getStatusText(String? review) {
    if (review == null || review.isEmpty) {
      return "Pending Review";
    }
    
    switch (review.toLowerCase()) {
      case 'high':
        return "High Priority";
      case 'medium':
        return "Medium Priority";
      case 'low':
        return "Low Priority";
      default:
        return "Reviewed";
    }
  }

  Color _getStatusColor(String? review) {
    if (review == null || review.isEmpty) {
      return const Color(0xff94A3B8);
    }
    
    switch (review.toLowerCase()) {
      case 'high':
        return const Color(0xffEF4444);
      case 'medium':
        return const Color(0xffF59E0B);
      case 'low':
        return const Color(0xff10B981);
      default:
        return const Color(0xff10B981);
    }
  }

  IconData _getStatusIcon(String? review) {
    if (review == null || review.isEmpty) {
      return Icons.pending_outlined;
    }
    return Icons.check_circle;
  }

  String _getDiagnosisDisplay(String? result) {
    if (result == null) return "Pending";
    if (result.toUpperCase() == 'LEPROSY') return "Leprosy";
    if (result.toUpperCase() == 'NOT LEPROSY') return "Not Leprosy";
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final hasReview = patient["doctor_review"] != null && 
                     patient["doctor_review"].toString().isNotEmpty;
    
    // Safely parse date
    String formattedDate = "Unknown date";
    try {
      final date = DateTime.parse(patient["created_at"]);
      formattedDate = DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      print("Error parsing date: ${patient["created_at"]}");
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
          ),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: hasReview 
                      ? _getStatusColor(patient["doctor_review"]).withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasReview 
                        ? _getStatusColor(patient["doctor_review"]).withOpacity(0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: hasReview
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: _getStatusColor(patient["doctor_review"]),
                      )
                    : null,
              ),
              
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 16),
              
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient["full_name"] ?? "Unknown Patient",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${patient["symptoms"] ?? "No symptoms"} • ${patient["affected_area"] ?? "Unknown area"}",
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(patient["doctor_review"]).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(patient["doctor_review"]).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(patient["doctor_review"]),
                            size: 14,
                            color: _getStatusColor(patient["doctor_review"]),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(patient["doctor_review"]),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(patient["doctor_review"]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Date and Result
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getResultColor(patient["diagnosis_result"]).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDiagnosisDisplay(patient["diagnosis_result"]),
                      style: TextStyle(
                        color: _getResultColor(patient["diagnosis_result"]),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: const Color(0xff94A3B8),
                size: isDesktop ? 24 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (patient["image_url"] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          patient["image_url"],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final name = patient["full_name"] ?? "U";
    final initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xffE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xff0F172A),
        ),
      ),
    );
  }

  Color _getResultColor(String? result) {
    if (result == null) return const Color(0xff94A3B8);
    
    switch (result.toUpperCase()) {
      case 'LEPROSY':
        return const Color(0xffEF4444);
      case 'NOT LEPROSY':
        return const Color(0xff10B981);
      default:
        return const Color(0xff94A3B8);
    }
  }
}