import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clothing_item.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';

class CreateOutfitScreen extends ConsumerStatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  ConsumerState<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends ConsumerState<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Reset any leftover draft from a previous session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftOutfitProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your outfit a name')),
      );
      return;
    }

    final draft = ref.read(draftOutfitProvider.notifier);
    if (draft.selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the outfit')),
      );
      return;
    }

    setState(() => _saving = true);

    await ref.read(outfitProvider.notifier).saveOutfit(
          name: name,
          itemIds: draft.selectedItemIds,
        );

    draft.reset();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftOutfitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Outfit'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Outfit name',
              hintText: 'e.g. Monday office look',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 28),

          Text(
            'Items',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          // One slot per category
          ...AppConstants.categories.map(
            (cat) => _CategorySlot(
              category: cat,
              selected: draft[cat],
              onTap: () => _pickItem(context, cat),
              onRemove: () =>
                  ref.read(draftOutfitProvider.notifier).removeCategory(cat),
            ),
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Outfit'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickItem(BuildContext context, String category) async {
    final items = ref.read(itemsByCategoryProvider(category));

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $category in your wardrobe yet')),
      );
      return;
    }

    final picked = await showModalBottomSheet<ClothingItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ItemPickerSheet(category: category, items: items),
    );

    if (picked != null) {
      ref.read(draftOutfitProvider.notifier).selectItem(picked);
    }
  }
}

// ── Category slot row ─────────────────────────────────────────────────────────

class _CategorySlot extends StatelessWidget {
  final String category;
  final ClothingItem? selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _CategorySlot({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Thumbnail or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: selected?.photoPath != null
                      ? Image.file(File(selected!.photoPath!), fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.add,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Category label + item name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected?.name ?? 'Tap to choose',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: selected != null ? null : Colors.grey[400],
                            fontWeight: selected != null ? FontWeight.w500 : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Remove button
              if (selected != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey[500],
                  onPressed: onRemove,
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item picker bottom sheet ──────────────────────────────────────────────────

class _ItemPickerSheet extends StatelessWidget {
  final String category;
  final List<ClothingItem> items;

  const _ItemPickerSheet({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Choose $category',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, item),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.photoPath != null
                              ? Image.file(File(item.photoPath!), fit: BoxFit.cover, width: double.infinity)
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.checkroom_outlined),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
