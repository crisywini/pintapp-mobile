import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/clothing_item.dart';
import '../providers/wardrobe_provider.dart';
import '../widgets/item_card.dart';

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredWardrobeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Pinta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add item',
              onPressed: () => context.push('/wardrobe/add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: selectedCategory == null,
                  onTap: () =>
                      ref.read(selectedCategoryProvider.notifier).state = null,
                ),
                ...AppConstants.categories.map(
                  (cat) => _CategoryChip(
                    label: cat,
                    selected: selectedCategory == cat,
                    onTap: () =>
                        ref.read(selectedCategoryProvider.notifier).state = cat,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: items.isEmpty
                ? _EmptyState(hasFilter: selectedCategory != null)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => ItemCard(
                      item: items[i],
                      onTap: () => context.push('/wardrobe/${items[i].id}'),
                      onLongPress: () =>
                          _showItemActions(context, ref, items[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/wardrobe/add'),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Long-press actions ────────────────────────────────────────────────────────

void _showItemActions(
    BuildContext context, WidgetRef ref, ClothingItem item) {
  showModalBottomSheet(
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
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            item.category,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(sheetCtx);
              context.push('/wardrobe/${item.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(sheetCtx);
              _confirmDeleteItem(context, ref, item);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _confirmDeleteItem(
    BuildContext context, WidgetRef ref, ClothingItem item) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Delete "${item.name}"?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(dialogCtx);
            ref.read(wardrobeProvider.notifier).deleteItem(item.id);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        // Explicit label color so M3's internal state logic can't override it
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : Colors.grey[800],
        ),
        selectedColor: AppTheme.babyBlue,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? AppTheme.babyBlue : Colors.grey[300]!,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No items in this category' : 'Your wardrobe is empty',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first piece',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }
}
