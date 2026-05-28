// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fragrance_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FragranceItemAdapter extends TypeAdapter<FragranceItem> {
  @override
  final int typeId = 2;

  @override
  FragranceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FragranceItem(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String,
      photoPath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FragranceItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FragranceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
