import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/clothing_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final wardrobeRepositoryProvider = Provider<WardrobeRepository>(
  (_) => WardrobeRepository(),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class WardrobeNotifier extends Notifier<List<ClothingItem>> {
  WardrobeRepository get _repo => ref.read(wardrobeRepositoryProvider);

  @override
  List<ClothingItem> build() => _repo.getAll();

  Future<void> addItem({
    required String name,
    required String category,
    required String color,
    required String occasion,
    XFile? photo,
  }) async {
    final id = const Uuid().v4();
    String? photoPath;

    if (photo != null) {
      photoPath = await _savePhoto(photo, id);
    }

    final item = ClothingItem(
      id: id,
      name: name,
      category: category,
      color: color,
      photoPath: photoPath,
      occasion: occasion,
    );

    await _repo.save(item);
    state = _repo.getAll();
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String category,
    required String color,
    required String occasion,
    XFile? newPhoto,
  }) async {
    final existing = _repo.getById(id);
    if (existing == null) return;

    String? photoPath = existing.photoPath;

    if (newPhoto != null) {
      // Delete the old photo file before replacing it
      if (existing.photoPath != null) {
        final old = File(existing.photoPath!);
        if (await old.exists()) await old.delete();
      }
      photoPath = await _savePhoto(newPhoto, id);
    }

    final updated = existing.copyWith(
      name: name,
      category: category,
      color: color,
      occasion: occasion,
      photoPath: photoPath,
    );

    await _repo.save(updated);
    state = _repo.getAll();
  }

  Future<void> deleteItem(String id) async {
    final item = _repo.getById(id);
    if (item?.photoPath != null) {
      final file = File(item!.photoPath!);
      if (await file.exists()) await file.delete();
    }
    await _repo.delete(id);
    state = _repo.getAll();
  }

  /// Copies [photo] into the app's documents folder under `wardrobe_photos/`.
  Future<String> _savePhoto(XFile photo, String itemId) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'wardrobe_photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final ext = p.extension(photo.path);
    final dest = p.join(photosDir.path, '$itemId$ext');
    await File(photo.path).copy(dest);
    return dest;
  }
}

final wardrobeProvider =
    NotifierProvider<WardrobeNotifier, List<ClothingItem>>(WardrobeNotifier.new);

// ── Derived: category filter ──────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredWardrobeProvider = Provider<List<ClothingItem>>((ref) {
  final items = ref.watch(wardrobeProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return items;
  return items.where((i) => i.category == category).toList();
});

// ── Derived: items for a specific category (used by outfit builder) ───────────

final itemsByCategoryProvider =
    Provider.family<List<ClothingItem>, String>((ref, category) {
  return ref.watch(wardrobeProvider).where((i) => i.category == category).toList();
});
