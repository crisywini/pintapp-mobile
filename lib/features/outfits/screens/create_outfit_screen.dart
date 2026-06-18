import 'dart:async';
import 'dart:io';
import 'dart:math';

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
  bool _showAnimation = false;

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
        _pickOutfitType();
      }
    });
  }

  Future<void> _pickOutfitType() async {
    final type = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OutfitTypeDialog(),
    );
    if (type == null) {
      if (mounted) context.pop();
      return;
    }
    ref.read(draftOutfitProvider.notifier).setOutfitType(type);
    if (mounted) setState(() => _showAnimation = true);
  }

  void _loadExistingOutfit() {
    final outfit = ref
        .read(outfitProvider)
        .where((o) => o.id == widget.editOutfitId)
        .firstOrNull;

    if (outfit == null) return;

    _nameController.text = outfit.name;

    final outfitType = outfit.outfitType ?? '3-piece';
    final wardrobe = ref.read(wardrobeProvider);
    final items = outfit.itemIds
        .map((id) => wardrobe.where((i) => i.id == id).firstOrNull)
        .whereType<ClothingItem>()
        .toList();
    ref.read(draftOutfitProvider.notifier).loadFromItems(items, outfitType);

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

    final draft = ref.read(draftOutfitProvider);
    final required = AppConstants.requiredSlots[draft.outfitType] ?? [];
    final missingSlots = required
        .where((cat) => (draft.slots[cat] ?? []).isEmpty)
        .toList();

    if (missingSlots.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a ${missingSlots.first}')),
      );
      return;
    }

    final notifier = ref.read(draftOutfitProvider.notifier);
    if (notifier.selectedItemIds.isEmpty) {
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
            itemIds: notifier.selectedItemIds,
            keepPhotoPaths: _keepPhotoPaths,
            removedPhotoPaths: _removedPhotoPaths.toList(),
            newPhotos: _newPhotos,
            outfitType: draft.outfitType,
          );
    } else {
      await ref.read(outfitProvider.notifier).saveOutfit(
            name: name,
            itemIds: notifier.selectedItemIds,
            outfitType: draft.outfitType,
          );
      notifier.reset();
    }

    if (mounted) context.pop();
  }

  Future<void> _pickItem(String category) async {
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
      ref.read(draftOutfitProvider.notifier).addItemToSlot(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showAnimation) {
      return _OutfitAnimationScreen(
        onComplete: () {
          if (mounted) setState(() { _showAnimation = false; _loaded = true; });
        },
      );
    }

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Edit Outfit' : 'New Outfit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final draft = ref.watch(draftOutfitProvider);
    final requiredCats = AppConstants.requiredSlots[draft.outfitType] ?? [];
    final optionalCats = AppConstants.optionalSlots[draft.outfitType] ?? [];

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

          // ── Required slots ──────────────────────────────────────────────
          Text(
            'Required',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...requiredCats.map(
            (cat) => _RequiredSlotCard(
              key: ValueKey('carousel_$cat'),
              category: cat,
              allItems: ref.watch(itemsByCategoryProvider(cat)),
            ),
          ),

          const SizedBox(height: 20),

          // ── Optional slots ──────────────────────────────────────────────
          Text(
            'Optional',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...optionalCats.map(
            (cat) => _OutfitSlotCard(
              category: cat,
              items: draft.slots[cat] ?? [],
              onAdd: () => _pickItem(cat),
              onRemove: (index) =>
                  ref.read(draftOutfitProvider.notifier).removeItemFromSlot(cat, index),
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
}

// ── Outfit loading animation ──────────────────────────────────────────────────

class _OutfitAnimationScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const _OutfitAnimationScreen({required this.onComplete});

  @override
  State<_OutfitAnimationScreen> createState() => _OutfitAnimationScreenState();
}

class _OutfitAnimationScreenState extends State<_OutfitAnimationScreen>
    with TickerProviderStateMixin {
  static const _phrases = [
    "reviewing Manolo's archives...",
    "consulting this week's Vogue...",
    "a Cosmo please, we're almost there...",
    "pressing the good trousers...",
    "asking Carrie for advice...",
    "checking the sock situation...",
    "ironing out the details...",
    "steaming the good stuff...",
    "finding the perfect light...",
    "Colombia called, it approved...",
    "the mirror doesn't lie, almost ready...",
    "picking the right fragrance...",
    "buttoning up...",
    "almost as good as the real thing...",
  ];

  late final AnimationController _swingController;
  late final Animation<double> _swingAngle;
  late final AnimationController _fadeController;

  late final List<String> _shuffled;
  int _phraseIndex = 0;
  Timer? _phraseTimer;
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();

    // Shuffle phrases so every session feels fresh
    _shuffled = List<String>.from(_phrases)..shuffle(Random());

    // Pendulum swing — hanger rocks left/right
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _swingAngle = Tween<double>(begin: -0.18, end: 0.18).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOut),
    );

    // Phrase fade controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );

    // Cycle to next phrase every ~2200 ms
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) async {
      if (!mounted) return;
      await _fadeController.reverse();
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _shuffled.length);
      _fadeController.forward();
    });

    // Finish after random 2–5 s
    final ms = 2000 + Random().nextInt(3001);
    _doneTimer = Timer(Duration(milliseconds: ms), widget.onComplete);
  }

  @override
  void dispose() {
    _swingController.dispose();
    _fadeController.dispose();
    _phraseTimer?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Swinging hanger
              AnimatedBuilder(
                animation: _swingAngle,
                builder: (context, child) => Transform.rotate(
                  angle: _swingAngle.value,
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.checkroom_outlined,
                    size: 96,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Fading phrase
              FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _shuffled[_phraseIndex],
                    key: ValueKey(_phraseIndex),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outfit type dialog ────────────────────────────────────────────────────────

class _OutfitTypeDialog extends StatefulWidget {
  const _OutfitTypeDialog();

  @override
  State<_OutfitTypeDialog> createState() => _OutfitTypeDialogState();
}

class _OutfitTypeDialogState extends State<_OutfitTypeDialog> {
  String _selected = '3-piece';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Outfit Type'),
      content: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (v) => setState(() => _selected = v!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            RadioListTile<String>(
              value: '3-piece',
              title: Text('3-Piece Outfit'),
              subtitle: Text('Top, Bottoms & Shoes'),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: '2-piece',
              title: Text('2-Piece Outfit'),
              subtitle: Text('Dress & Shoes'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// ── Per-slot carousel card ────────────────────────────────────────────────────

class _OutfitSlotCard extends StatefulWidget {
  final String category;
  final List<ClothingItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _OutfitSlotCard({
    required this.category,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_OutfitSlotCard> createState() => _OutfitSlotCardState();
}

class _OutfitSlotCardState extends State<_OutfitSlotCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(_OutfitSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If item was removed and we're past the end, jump back
    if (widget.items.isNotEmpty && _currentPage >= widget.items.length) {
      final newPage = widget.items.length - 1;
      _currentPage = newPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(newPage);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: widget.items.isEmpty ? _buildEmpty() : _buildCarousel(),
    );
  }

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: widget.onAdd,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
            // Dashed border via custom painter would require a package;
            // using a solid border is simpler and avoids extra deps.
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 6),
            Text(
              'Add ${widget.category}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    final items = widget.items;
    final showArrows = items.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Category label
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Text(
                  widget.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_currentPage + 1} / ${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              ],
            ),
          ),

          // PageView row: left arrow | card | right arrow
          SizedBox(
            height: 150,
            child: Row(
              children: [
                // Left arrow
                SizedBox(
                  width: 36,
                  child: showArrows && _currentPage > 0
                      ? IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      : null,
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Stack(
                          children: [
                            // Item photo + name
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: item.photoPath != null
                                          ? Image.file(
                                              File(item.photoPath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                color: Colors.grey[100],
                                                child: const Icon(
                                                    Icons.checkroom_outlined),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[100],
                                              child: const Icon(
                                                  Icons.checkroom_outlined),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            // Remove (×) button — top-right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => widget.onRemove(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Right arrow
                SizedBox(
                  width: 36,
                  child: showArrows && _currentPage < items.length - 1
                      ? IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Dot indicators + add button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dot indicators
                if (showArrows)
                  ...List.generate(items.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentPage ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),

                const Spacer(),

                // Add another item to this slot
                GestureDetector(
                  onTap: widget.onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 2),
                        Text(
                          'Add',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: Colors.grey[200]),
              ),
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

// ── Required slot carousel ────────────────────────────────────────────────────
// Shows ALL wardrobe items for the category in a carousel.
// Whichever item is currently visible is the one selected for the outfit.

class _RequiredSlotCard extends ConsumerStatefulWidget {
  final String category;
  final List<ClothingItem> allItems;

  const _RequiredSlotCard({
    super.key,
    required this.category,
    required this.allItems,
  });

  @override
  ConsumerState<_RequiredSlotCard> createState() => _RequiredSlotCardState();
}

class _RequiredSlotCardState extends ConsumerState<_RequiredSlotCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // In edit mode, start at the item that was previously saved for this slot.
    final selected =
        ref.read(draftOutfitProvider).slots[widget.category];
    int initialPage = 0;
    if (selected != null &&
        selected.isNotEmpty &&
        widget.allItems.isNotEmpty) {
      final idx =
          widget.allItems.indexWhere((i) => i.id == selected.first.id);
      if (idx >= 0) initialPage = idx;
    }

    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);

    // Register the initial visible item as the selection.
    if (widget.allItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(draftOutfitProvider.notifier)
              .setSlotItem(widget.allItems[initialPage]);
        }
      });
    }
  }

  @override
  void didUpdateWidget(_RequiredSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allItems != oldWidget.allItems &&
        widget.allItems.isNotEmpty &&
        _currentPage >= widget.allItems.length) {
      final clamped = widget.allItems.length - 1;
      setState(() => _currentPage = clamped);
      _pageController.jumpToPage(clamped);
      ref
          .read(draftOutfitProvider.notifier)
          .setSlotItem(widget.allItems[clamped]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    ref
        .read(draftOutfitProvider.notifier)
        .setSlotItem(widget.allItems[page]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: widget.allItems.isEmpty
          ? _buildEmpty()
          : _buildCarousel(),
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 32, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Text(
            'No ${widget.category} in wardrobe yet',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final items = widget.allItems;
    final showArrows = items.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Category label + "X / N" counter
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Text(
                  widget.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_currentPage + 1} / ${items.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Left arrow | PageView | Right arrow
          SizedBox(
            height: 150,
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: showArrows && _currentPage > 0
                      ? IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : null,
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: item.photoPath != null
                                      ? Image.file(
                                          File(item.photoPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Container(
                                            color: Colors.grey[100],
                                            child: const Icon(
                                                Icons.checkroom_outlined),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                              Icons.checkroom_outlined),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: 36,
                  child: showArrows && _currentPage < items.length - 1
                      ? IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Dot indicators (only when few enough items to display cleanly)
          if (showArrows && items.length <= 10)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentPage ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
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
                              ? Image.file(
                                  File(item.photoPath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, _, _) => Container(
                                    color: Colors.grey[100],
                                    child:
                                        const Icon(Icons.checkroom_outlined),
                                  ),
                                )
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
