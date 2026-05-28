import 'package:hive/hive.dart';

part 'fragrance_item.g.dart';

@HiveType(typeId: 2)
class FragranceItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String brand;

  @HiveField(3)
  final String? photoPath;

  const FragranceItem({
    required this.id,
    required this.name,
    required this.brand,
    this.photoPath,
  });

  FragranceItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? photoPath,
  }) {
    return FragranceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
