import 'package:hive/hive.dart';

part 'outfit.g.dart';

@HiveType(typeId: 1)
class Outfit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// Item IDs — max one per category, enforced by the provider.
  @HiveField(2)
  final List<String> itemIds;

  /// Optional photos taken specifically for this outfit (lookbook style).
  /// Existing outfits without this field will load with an empty list.
  @HiveField(3)
  final List<String> photoPaths;

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.photoPaths = const [],
  });

  Outfit copyWith({
    String? id,
    String? name,
    List<String>? itemIds,
    List<String>? photoPaths,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }
}
