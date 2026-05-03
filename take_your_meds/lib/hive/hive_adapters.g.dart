// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class DosePresetAdapter extends TypeAdapter<DosePreset> {
  @override
  final typeId = 1;

  @override
  DosePreset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DosePreset(
      id: fields[3] as String,
      dosage: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DosePreset obj) {
    writer
      ..writeByte(2)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DosePresetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedsAdapter extends TypeAdapter<Meds> {
  @override
  final typeId = 2;

  @override
  Meds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meds(
      name: fields[0] as String,
      id: fields[1] as String,
      range: fields[2] as MedsDoseRange,
      duration: fields[3] as Duration,
      doses: fields[4] == null
          ? const []
          : (fields[4] as List).cast<DosePreset>(),
    );
  }

  @override
  void write(BinaryWriter writer, Meds obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.range)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.doses);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedsDoseRangeAdapter extends TypeAdapter<MedsDoseRange> {
  @override
  final typeId = 3;

  @override
  MedsDoseRange read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MedsDoseRange.ug;
      case 1:
        return MedsDoseRange.mg;
      case 2:
        return MedsDoseRange.g;
      default:
        return MedsDoseRange.ug;
    }
  }

  @override
  void write(BinaryWriter writer, MedsDoseRange obj) {
    switch (obj) {
      case MedsDoseRange.ug:
        writer.writeByte(0);
      case MedsDoseRange.mg:
        writer.writeByte(1);
      case MedsDoseRange.g:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedsDoseRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActiveMedsAdapter extends TypeAdapter<ActiveMeds> {
  @override
  final typeId = 4;

  @override
  ActiveMeds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveMeds(
      id: fields[0] as String,
      meds: fields[5] as Meds,
      dose: fields[1] as DosePreset,
      takenAt: fields[2] as DateTime,
      remindAt: fields[3] as DateTime,
      remindAgainAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveMeds obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dose)
      ..writeByte(2)
      ..write(obj.takenAt)
      ..writeByte(3)
      ..write(obj.remindAt)
      ..writeByte(4)
      ..write(obj.remindAgainAt)
      ..writeByte(5)
      ..write(obj.meds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveMedsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
