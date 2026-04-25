import 'package:hive/hive.dart';

part 'pending_diagnosis.g.dart';

@HiveType(typeId: 4)
class PendingDiagnosis extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fullName;

  @HiveField(2)
  String age;

  @HiveField(3)
  String gender;

  @HiveField(4)
  String phone;

  @HiveField(5)
  String symptoms;

  @HiveField(6)
  String affectedArea;

  @HiveField(7)
  String imagePath; // absolute local file path

  @HiveField(8)
  String syncStatus; // 'pending' | 'sending' | 'synced' | 'failed'

  @HiveField(9)
  DateTime createdAt;

  PendingDiagnosis({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.phone,
    required this.symptoms,
    required this.affectedArea,
    required this.imagePath,
    required this.syncStatus,
    required this.createdAt,
  });
}