import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../models/fragrance_item.dart';

class FragranceRepository {
  Box<FragranceItem> get _box =>
      Hive.box<FragranceItem>(AppConstants.fragrancesBoxName);

  List<FragranceItem> getAll() => _box.values.toList();

  FragranceItem? getById(String id) {
    try {
      return _box.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(FragranceItem item) => _box.put(item.id, item);

  Future<void> delete(String id) => _box.delete(id);
}
