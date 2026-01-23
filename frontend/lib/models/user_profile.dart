import 'package:hive/hive.dart';

part 'user_profile.g.dart';

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

  UserProfile({
    required this.id,
    this.fullName,
    this.age,
    this.gender,
  });
}
