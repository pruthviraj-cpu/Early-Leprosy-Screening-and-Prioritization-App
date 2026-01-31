import 'package:flutter/material.dart';
import '../model/user_profile.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserProfile? profile;
  final bool isEditing;
  final Function(String)? onNameChanged;
  final Function(int?)? onAgeChanged;
  final Function(String?)? onGenderChanged;
  final Function(String?)? onPhoneChanged;

  const ProfileInfoCard({
    super.key,
    required this.profile,
    this.isEditing = false,
    this.onNameChanged,
    this.onAgeChanged,
    this.onGenderChanged,
    this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            
            // Full Name
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: profile?.fullName ?? 'Not set',
              isEditing: isEditing,
              // onChanged: onNameChanged,
            ),
            
            const Divider(height: 30),
            
            // Age
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: profile?.age?.toString() ?? 'Not set',
              isEditing: isEditing,
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  onAgeChanged?.call(int.tryParse(value));
                }
              },
            ),
            
            const Divider(height: 30),
            
            // Gender
            _buildInfoRow(
              icon: Icons.transgender,
              label: 'Gender',
              value: profile?.gender ?? 'Not set',
              isEditing: isEditing,
              isDropdown: true,
              dropdownOptions: const ['Male', 'Female', 'Other'],
              onChanged: onGenderChanged,
            ),
            
            const Divider(height: 30),
            
            // Phone Number
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: profile?.phoneNumber ?? 'Not set',
              isEditing: isEditing,
              keyboardType: TextInputType.phone,
              onChanged: onPhoneChanged,
            ),
            
            const SizedBox(height: 10),
          ],
        ),
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
      children: [
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              if (isEditing)
                isDropdown
                    ? DropdownButton<String>(
                        value: value == 'Not set' ? null : value,
                        isExpanded: true,
                        underline: Container(
                          height: 1,
                          color: Colors.blue.shade200,
                        ),
                        hint: const Text('Select gender'),
                        items: dropdownOptions
                            ?.map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ))
                            .toList(),
                        onChanged: onChanged,
                      )
                    : TextField(
                        controller: TextEditingController(text: value == 'Not set' ? '' : value),
                        decoration: InputDecoration(
                          hintText: 'Enter $label',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: keyboardType,
                        onChanged: onChanged,
                      )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}