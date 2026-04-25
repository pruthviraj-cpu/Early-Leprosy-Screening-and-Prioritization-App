import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/user_profile.dart';

const _blue      = Color(0xFF1A73E8);
const _blueLight = Color(0xFFE8F0FE);
const _surface   = Color(0xFFFFFFFF);
const _fill      = Color(0xFFF8F9FA);
const _border    = Color(0xFFE8EAED);
const _textPri   = Color(0xFF1F1F1F);
const _textSec   = Color(0xFF5F6368);
const _textHint  = Color(0xFF9AA0A6);

class ProfileInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController phoneController;
  final UserProfile? profile;
  final bool isEditing;
  final Function(String?)? onGenderChanged;

  const ProfileInfoCard({
    super.key,
    required this.profile,
    required this.isEditing,
    required this.nameController,
    required this.ageController,
    required this.phoneController,
    this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _blue,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1, color: _border),

          _Row(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: profile?.fullName,
            controller: nameController,
            isEditing: isEditing,
          ),
          const Divider(height: 1, indent: 56, color: _border),

          _Row(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: profile?.age?.toString(),
            controller: ageController,
            isEditing: isEditing,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const Divider(height: 1, indent: 56, color: _border),

          _GenderRow(
            value: profile?.gender,
            isEditing: isEditing,
            onChanged: onGenderChanged,
          ),
          const Divider(height: 1, indent: 56, color: _border),

          _Row(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile?.phoneNumber,
            controller: phoneController,
            isEditing: isEditing,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

// ── Single info row ───────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final TextEditingController controller;
  final bool isEditing;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.controller,
    required this.isEditing,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Icon
          SizedBox(
            width: 40,
            child: Icon(icon, size: 20, color: const Color(0xFF5F6368)),
          ),
          const SizedBox(width: 0),
          // Content
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textPri,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle:
                          const TextStyle(color: _blue, fontSize: 12),
                      hintText: 'Enter $label',
                      hintStyle:
                          const TextStyle(color: _textHint, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _textSec,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          value?.isNotEmpty == true ? value! : '—',
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textPri,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Gender dropdown row ───────────────────────────────────────────────────────
class _GenderRow extends StatelessWidget {
  final String? value;
  final bool isEditing;
  final Function(String?)? onChanged;

  const _GenderRow({
    required this.value,
    required this.isEditing,
    this.onChanged,
  });

  static const _options = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Icon(Icons.wc_outlined, size: 20, color: Color(0xFF5F6368)),
          ),
          Expanded(
            child: isEditing
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: (_options.contains(value)) ? value : null,
                      isExpanded: true,
                      hint: const Text('Select Gender',
                          style: TextStyle(color: _textHint, fontSize: 14)),
                      style: const TextStyle(
                          fontSize: 14,
                          color: _textPri,
                          fontWeight: FontWeight.w500),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _textSec, size: 20),
                      items: _options
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: onChanged,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender',
                            style: TextStyle(
                                fontSize: 11,
                                color: _textSec,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          value?.isNotEmpty == true ? value! : '—',
                          style: const TextStyle(
                              fontSize: 14,
                              color: _textPri,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}