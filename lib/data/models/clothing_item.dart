import 'package:hive/hive.dart';

part 'clothing_item.g.dart';

@HiveType(typeId: 0)
class ClothingItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String color;

  @HiveField(4)
  final String? photoPath;

  @HiveField(5)
  final String occasion;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.photoPath,
    required this.occasion,
  });

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? color,
    String? photoPath,
    String? occasion,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      photoPath: photoPath ?? this.photoPath,
      occasion: occasion ?? this.occasion,
    );
  }
}
