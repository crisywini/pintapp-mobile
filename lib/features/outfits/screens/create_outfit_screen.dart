import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clothing_item.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../providers/outfit_provider.dart';

class CreateOutfitScreen extends ConsumerStatefulWidget {
  final String? editOutfitId;
  const CreateOutfitScreen({super.key, this.editOutfitId});

  bool get isEditing => editOutfitId != null;

  @override
  ConsumerState<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends ConsumerState<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  // Photo state (edit mode only)
  List<String> _existingPhotoPaths = [];
  final Set<String> _removedPhotoPaths = {};
  final List<XFile> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditing) {
        _loadExistingOutfit();
      } else {
        ref.read(draftOutfitProvider.notifier).reset();
        setState(() => _loaded = true);
      }
    });
  }

  void _loadExistingOutfit() {
    final outfit = ref
        .read(outfitProvider)
        .where((o) => o.id == widget.editOutfitId)
        .firstOrNull;

    if (outfit == null) return;

    _nameController.text = outfit.name;

    // Pre-populate category slots with the outfit's items
    final wardrobe = ref.read(wardrobeProvider);
    final items = outfit.itemIds
        .map((id) => wardrobe.where((i) => i.id == id).firstOrNull)
        .whereType<ClothingItem>()
        .toList();
    ref.read(draftOutfitProvider.notifier).loadFromItems(items);

    setState(() {
      _existingPhotoPaths = List.from(outfit.photoPaths);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> get _keepPhotoPaths =>
      _existingPhotoPaths.where((p) => !_removedPhotoPaths.contains(p)).toList();

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _newPhotos.add(picked));
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

    if (widget.isEditing) {
      await ref.read(outfitProvider.notifier).updateOutfit(
            id: widget.editOutfitId!,
            name: name,
            itemIds: draft.selectedItemIds,
            keepPhotoPaths: _keepPhotoPaths,
            removedPhotoPaths: _removedPhotoPaths.toList(),
            newPhotos: _newPhotos,
          );
    } else {
      await ref.read(outfitProvider.notifier).saveOutfit(
            name: name,
            itemIds: draft.selectedItemIds,
          );
      draft.reset();
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Edit Outfit' : 'New Outfit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final draft = ref.watch(draftOutfitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Outfit' : 'New Outfit'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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

          // ── Photos (edit mode only) ─────────────────────────────────────
          if (widget.isEditing) ...[
            const SizedBox(height: 28),
            Text(
              'Photos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _PhotoStrip(
              existingPaths: _keepPhotoPaths,
              newPhotos: _newPhotos,
              onRemoveExisting: (path) =>
                  setState(() => _removedPhotoPaths.add(path)),
              onRemoveNew: (index) =>
                  setState(() => _newPhotos.removeAt(index)),
              onAdd: _pickPhoto,
            ),
          ],

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
                : Text(widget.isEditing ? 'Update Outfit' : 'Save Outfit'),
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

// ── Photo strip (edit mode) ───────────────────────────────────────────────────

class _PhotoStrip extends StatelessWidget {
  final List<String> existingPaths;
  final List<XFile> newPhotos;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;
  final VoidCallback onAdd;

  const _PhotoStrip({
    required this.existingPaths,
    required this.newPhotos,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final total = existingPaths.length + newPhotos.length;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing saved photos
          ...existingPaths.map(
            (path) => _PhotoThumb(
              child: Image.file(File(path), fit: BoxFit.cover),
              onRemove: () => onRemoveExisting(path),
            ),
          ),

          // Newly picked (not yet saved)
          ...List.generate(
            newPhotos.length,
            (i) => _PhotoThumb(
              child: Image.file(File(newPhotos[i].path), fit: BoxFit.cover),
              onRemove: () => onRemoveNew(i),
            ),
          ),

          // Add button
          if (total < 6)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.grey[400], size: 28),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: selected?.photoPath != null
                      ? Image.file(File(selected!.photoPath!), fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(Icons.add, color: Colors.grey[400]),
                        ),
                ),
              ),
              const SizedBox(width: 14),
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
                            fontWeight:
                                selected != null ? FontWeight.w500 : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
                              ? Image.file(File(item.photoPath!),
                                  fit: BoxFit.cover, width: double.infinity)
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
