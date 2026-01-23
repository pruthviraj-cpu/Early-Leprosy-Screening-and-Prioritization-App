// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnosis_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiagnosisResultAdapter extends TypeAdapter<DiagnosisResult> {
  @override
  final int typeId = 3;

  @override
  DiagnosisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagnosisResult(
      diseaseName: fields[0] as String,
      probability: fields[1] as double,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisResult obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.diseaseName)
      ..writeByte(1)
      ..write(obj.probability)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
