import 'package:flutter/material.dart';
import '../model/user_profile.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xff0EA5A4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: profile?.fullName ?? 'Not set',
            isEditing: isEditing,
          ),

          const Divider(height: 30, color: Color(0xffF1F5F9)),

          // Age
          _buildInfoRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: profile?.age?.toString() ?? 'Not set',
            isEditing: isEditing,
          ),

          const Divider(height: 30, color: Color(0xffF1F5F9)),

          // Gender
          _buildInfoRow(
            icon: Icons.transgender_outlined,
            label: 'Gender',
            value: profile?.gender ?? 'Not set',
            isEditing: isEditing,
            isDropdown: true,
            dropdownOptions: const ['Male', 'Female', 'Other'],
            onChanged: onGenderChanged,
          ),

          const Divider(height: 30, color: Color(0xffF1F5F9)),

          // Phone Number
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: profile?.phoneNumber ?? 'Not set',
            isEditing: isEditing,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    bool isDropdown = false,
    List<String>? dropdownOptions,
    TextInputType keyboardType = TextInputType.text,
    Function(String?)? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xff64748B), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xff64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              if (isEditing)
                isDropdown
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: value == 'Not set' ? null : value,
                            isExpanded: true,
                            hint: const Text(
                              'Select gender',
                              style: TextStyle(
                                color: Color(0xff94A3B8),
                                fontSize: 15,
                              ),
                            ),
                            items: dropdownOptions
                                ?.map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xff0F172A),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: onChanged,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xff0F172A),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: TextField(
                          // !changes for name
                          controller: label == 'Full Name'
                              ? nameController
                              : label == 'Age'
                              ? ageController
                              : phoneController,
                          decoration: InputDecoration(
                            hintText: 'Enter $label',
                            hintStyle: const TextStyle(
                              color: Color(0xff94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xff0F172A),
                          ),
                          keyboardType: keyboardType,
                          onChanged: onChanged,
                        ),
                      )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
