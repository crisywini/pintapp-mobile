import 'package:hive/hive.dart';

class Outfit {
  final String id;
  final String name;

  /// Item IDs — max one per category, enforced by the provider.
  final List<String> itemIds;

  /// Optional photos taken specifically for this outfit (lookbook style).
  /// Existing outfits without this field will load with an empty list.
  final List<String> photoPaths;

  /// '3-piece' or '2-piece'. Null for outfits saved before this field was added.
  final String? outfitType;

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.photoPaths = const [],
    this.outfitType,
  });

  Outfit copyWith({
    String? id,
    String? name,
    List<String>? itemIds,
    List<String>? photoPaths,
    String? outfitType,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      photoPaths: photoPaths ?? this.photoPaths,
      outfitType: outfitType ?? this.outfitType,
    );
  }
}

// ── Manual TypeAdapter (typeId: 1) ────────────────────────────────────────────
// Written by hand so build_runner can never overwrite it. The null-safe cast
// on photoPaths (field 3) handles outfits saved before that field existed.

class OutfitAdapter extends TypeAdapter<Outfit> {
  @override
  final int typeId = 1;

  @override
  Outfit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Outfit(
      id: fields[0] as String,
      name: fields[1] as String,
      itemIds: (fields[2] as List).cast<String>(),
      photoPaths: (fields[3] as List?)?.cast<String>() ?? const [],
      outfitType: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Outfit obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.itemIds)
      ..writeByte(3)
      ..write(obj.photoPaths)
      ..writeByte(4)
      ..write(obj.outfitType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
