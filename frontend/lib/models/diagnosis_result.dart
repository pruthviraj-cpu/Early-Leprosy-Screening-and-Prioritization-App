import 'package:hive/hive.dart';
   //flutter pub run build_runner build.
part 'diagnosis_result.g.dart';

@HiveType(typeId: 3)
class DiagnosisResult extends HiveObject {
  @HiveField(0)
  String diseaseName;

  @HiveField(1)
  double probability;

  @HiveField(2)
  DateTime createdAt;

  DiagnosisResult({
    required this.diseaseName,
    required this.probability,
    required this.createdAt,
  });
}
