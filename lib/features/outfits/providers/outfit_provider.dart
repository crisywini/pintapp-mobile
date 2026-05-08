import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> saveOutfit({required String name, required List<String> itemIds}) async {
    final outfit = Outfit(
      id: const Uuid().v4(),
      name: name,
      itemIds: itemIds,
    );
    await _repo.save(outfit);
    state = _repo.getAll();
  }

  Future<void> deleteOutfit(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final outfitProvider =
    NotifierProvider<OutfitNotifier, List<Outfit>>(OutfitNotifier.new);

// ── Draft outfit state (used while creating an outfit) ────────────────────────

/// Maps category → selected ClothingItem while building an outfit.
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

  void reset() => state = {};

  List<String> get selectedItemIds => state.values.map((i) => i.id).toList();
}

final draftOutfitProvider =
    NotifierProvider<DraftOutfitNotifier, Map<String, ClothingItem>>(
  DraftOutfitNotifier.new,
);

// ── Resolved items for an outfit (used in detail view) ───────────────────────

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
