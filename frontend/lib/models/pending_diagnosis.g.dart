// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_diagnosis.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingDiagnosisAdapter extends TypeAdapter<PendingDiagnosis> {
  @override
  final int typeId = 4;

  @override
  PendingDiagnosis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingDiagnosis(
      id: fields[0] as String,
      fullName: fields[1] as String,
      age: fields[2] as String,
      gender: fields[3] as String,
      phone: fields[4] as String,
      symptoms: fields[5] as String,
      affectedArea: fields[6] as String,
      imagePath: fields[7] as String,
      syncStatus: fields[8] as String,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PendingDiagnosis obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.symptoms)
      ..writeByte(6)
      ..write(obj.affectedArea)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingDiagnosisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
