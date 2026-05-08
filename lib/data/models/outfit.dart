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

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
  });

  Outfit copyWith({
    String? id,
    String? name,
    List<String>? itemIds,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
    );
  }
}
