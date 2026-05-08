import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../models/outfit.dart';

class OutfitRepository {
  Box<Outfit> get _box => Hive.box<Outfit>(AppConstants.outfitsBoxName);

  List<Outfit> getAll() => _box.values.toList();

  Outfit? getById(String id) {
    try {
      return _box.values.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Outfit outfit) => _box.put(outfit.id, outfit);

  Future<void> delete(String id) => _box.delete(id);
}
