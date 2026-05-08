import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../models/clothing_item.dart';

class WardrobeRepository {
  Box<ClothingItem> get _box => Hive.box<ClothingItem>(AppConstants.wardrobeBoxName);

  List<ClothingItem> getAll() => _box.values.toList();

  ClothingItem? getById(String id) {
    try {
      return _box.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ClothingItem item) => _box.put(item.id, item);

  Future<void> delete(String id) => _box.delete(id);
}
