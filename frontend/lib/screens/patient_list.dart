import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientListItem extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  final bool isDesktop;

  const PatientListItem({
    super.key,
    required this.patient,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  State<PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<PatientListItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final diagnosis = widget.patient["latest_diagnosis"];
    final probability = (diagnosis?["probability"] as num?)?.toDouble() ?? 0.0;
    final result = diagnosis?["diagnosis_result"];
    final imageUrl = diagnosis?["image_url"];
    final createdAt = diagnosis?["created_at"];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xffF1F5F9) : Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
            boxShadow: _hovering && widget.isDesktop
                ? [
                    BoxShadow(
                      color: const Color(0xff0F172A).withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}),
              const SizedBox(width: 12),
              _buildAvatar(imageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCenterContent(diagnosis, result, probability),
              ),
              const SizedBox(width: 12),
              _buildRightSection(createdAt, probability, result),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }

    final initials = widget.patient["full_name"]
        .toString()
        .trim()
        .split(" ")
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

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
          color: Color(0xff0F172A),
        ),
      ),
    );
  }

  Widget _buildCenterContent(
    Map<String, dynamic>? diagnosis,
    String? result,
    double probability,
  ) {
    final symptoms = diagnosis?["symptoms"] ?? "";
    final area = diagnosis?["affected_area"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.patient["full_name"] ?? "",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$symptoms • $area",
          style: const TextStyle(color: Color(0xff64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          _getPreviewText(result, probability),
          style: const TextStyle(color: Color(0xff475569), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRightSection(
    String? createdAt,
    double probability,
    String? result,
  ) {
    final formattedDate = createdAt != null
        ? DateFormat("d MMM yyyy").format(DateTime.parse(createdAt))
        : "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Color(0xff64748B)),
        ),
        const SizedBox(height: 8),
        _buildStatusBadge(probability, result),
      ],
    );
  }

  Widget _buildStatusBadge(double probability, String? result) {
    if (result == null) {
      return _badge("Pending Review", const Color(0xffF59E0B));
    }

    if (probability == 0) {
      return _badge("Awaiting AI Result", const Color(0xff64748B));
    }

    if (probability > 0.8) {
      return _badge(
        "${(probability * 100).toStringAsFixed(0)}%",
        const Color(0xffEF4444),
      );
    } else if (probability > 0.5) {
      return _badge(
        "${(probability * 100).toStringAsFixed(0)}%",
        const Color(0xffF59E0B),
      );
    } else {
      return _badge(
        "${(probability * 100).toStringAsFixed(0)}%",
        const Color(0xff10B981),
      );
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getPreviewText(String? result, double probability) {
    if (result == null) return "Diagnosis pending review";
    if (probability == 0) return "AI processing...";
    return "$result • ${(probability * 100).toStringAsFixed(0)}% confidence";
  }
}
