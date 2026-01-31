import 'package:hive/hive.dart';

part '../../../models/user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? fullName;

  @HiveField(2)
  int? age;

  @HiveField(3)
  String? gender;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? phoneNumber;

  @HiveField(6)
  String? profileImageUrl;

  @HiveField(7)
  DateTime? createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.age,
    this.gender,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Helper method to get initials for avatar
  String get initials {
    if (fullName == null || fullName!.isEmpty) return 'U';
    final parts = fullName!.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  // Helper method to get display name
  String get displayName {
    return fullName ?? email?.split('@').first ?? 'User';
  }
}