import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clothing_item.dart';
import '../../../data/models/outfit.dart';
import '../../../data/repositories/outfit_repository.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final outfitRepositoryProvider = Provider<OutfitRepository>(
  (_) => OutfitRepository(),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class OutfitNotifier extends Notifier<List<Outfit>> {
  OutfitRepository get _repo => ref.read(outfitRepositoryProvider);

  @override
  List<Outfit> build() => _repo.getAll();

  Future<void> saveOutfit({
    required String name,
    required List<String> itemIds,
  }) async {
    final outfit = Outfit(
      id: const Uuid().v4(),
      name: name,
      itemIds: itemIds,
    );
    await _repo.save(outfit);
    state = _repo.getAll();
  }

  Future<void> updateOutfit({
    required String id,
    required String name,
    required List<String> itemIds,
    required List<String> keepPhotoPaths,
    List<String> removedPhotoPaths = const [],
    List<XFile> newPhotos = const [],
  }) async {
    // Delete removed files from disk
    for (final path in removedPhotoPaths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    // Persist new picks
    final savedPaths = <String>[];
    for (final xfile in newPhotos) {
      savedPaths.add(await _savePhoto(xfile, '${id}_${const Uuid().v4()}'));
    }

    final updated = Outfit(
      id: id,
      name: name,
      itemIds: itemIds,
      photoPaths: [...keepPhotoPaths, ...savedPaths],
    );

    await _repo.save(updated);
    state = _repo.getAll();
  }

  Future<void> deleteOutfit(String id) async {
    final outfit = _repo.getById(id);
    if (outfit != null) {
      for (final path in outfit.photoPaths) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await _repo.delete(id);
    state = _repo.getAll();
  }

  Future<String> _savePhoto(XFile photo, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'outfit_photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final ext = p.extension(photo.path);
    final dest = p.join(photosDir.path, '$baseName$ext');
    await File(photo.path).copy(dest);
    return dest;
  }
}

final outfitProvider =
    NotifierProvider<OutfitNotifier, List<Outfit>>(OutfitNotifier.new);

// ── Draft outfit state ────────────────────────────────────────────────────────

/// Maps category → selected ClothingItem while building/editing an outfit.
class DraftOutfitNotifier extends Notifier<Map<String, ClothingItem>> {
  @override
  Map<String, ClothingItem> build() => {};

  void selectItem(ClothingItem item) {
    state = {...state, item.category: item};
  }

  void removeCategory(String category) {
    final next = Map<String, ClothingItem>.from(state);
    next.remove(category);
    state = next;
  }

  /// Pre-populates the draft when editing an existing outfit.
  void loadFromItems(List<ClothingItem> items) {
    state = {for (final item in items) item.category: item};
  }

  void reset() => state = {};

  List<String> get selectedItemIds => state.values.map((i) => i.id).toList();
}

final draftOutfitProvider =
    NotifierProvider<DraftOutfitNotifier, Map<String, ClothingItem>>(
  DraftOutfitNotifier.new,
);

// ── Resolved items for an outfit ─────────────────────────────────────────────

final outfitItemsProvider =
    Provider.family<List<ClothingItem>, String>((ref, outfitId) {
  final outfits = ref.watch(outfitProvider);
  final wardrobe = ref.watch(wardrobeProvider);

  final outfit = outfits.where((o) => o.id == outfitId).firstOrNull;
  if (outfit == null) return [];

  return outfit.itemIds
      .map((id) => wardrobe.where((item) => item.id == id).firstOrNull)
      .whereType<ClothingItem>()
      .toList();
});

// ── Sorted by category display order ─────────────────────────────────────────

List<ClothingItem> sortByCategoryOrder(List<ClothingItem> items) {
  final order = AppConstants.categories;
  return [...items]..sort((a, b) =>
      order.indexOf(a.category).compareTo(order.indexOf(b.category)));
}
