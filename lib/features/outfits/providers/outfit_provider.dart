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
    required String outfitType,
  }) async {
    final outfit = Outfit(
      id: const Uuid().v4(),
      name: name,
      itemIds: itemIds,
      outfitType: outfitType,
    );
    await _repo.save(outfit);
    state = _repo.getAll();
  }

  Future<void> updateOutfit({
    required String id,
    required String name,
    required List<String> itemIds,
    required List<String> keepPhotoPaths,
    required String outfitType,
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
      outfitType: outfitType,
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

class DraftOutfitState {
  final String outfitType;
  final Map<String, List<ClothingItem>> slots;

  const DraftOutfitState({
    required this.outfitType,
    required this.slots,
  });

  DraftOutfitState copyWith({
    String? outfitType,
    Map<String, List<ClothingItem>>? slots,
  }) {
    return DraftOutfitState(
      outfitType: outfitType ?? this.outfitType,
      slots: slots ?? this.slots,
    );
  }
}

class DraftOutfitNotifier extends Notifier<DraftOutfitState> {
  @override
  DraftOutfitState build() =>
      const DraftOutfitState(outfitType: '3-piece', slots: {});

  void setOutfitType(String type) {
    state = DraftOutfitState(outfitType: type, slots: {});
  }

  void addItemToSlot(ClothingItem item) {
    final updated = Map<String, List<ClothingItem>>.from(
      state.slots.map((k, v) => MapEntry(k, List<ClothingItem>.from(v))),
    );
    final list = updated.putIfAbsent(item.category, () => []);
    list.add(item);
    state = state.copyWith(slots: updated);
  }

  void removeItemFromSlot(String category, int index) {
    final updated = Map<String, List<ClothingItem>>.from(
      state.slots.map((k, v) => MapEntry(k, List<ClothingItem>.from(v))),
    );
    final list = updated[category];
    if (list == null) return;
    list.removeAt(index);
    if (list.isEmpty) updated.remove(category);
    state = state.copyWith(slots: updated);
  }

  void loadFromItems(List<ClothingItem> items, String outfitType) {
    final slots = <String, List<ClothingItem>>{};
    for (final item in items) {
      slots.putIfAbsent(item.category, () => []).add(item);
    }
    state = DraftOutfitState(outfitType: outfitType, slots: slots);
  }

  void reset() =>
      state = const DraftOutfitState(outfitType: '3-piece', slots: {});

  List<String> get selectedItemIds =>
      state.slots.values.expand((list) => list).map((i) => i.id).toList();
}

final draftOutfitProvider =
    NotifierProvider<DraftOutfitNotifier, DraftOutfitState>(
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
