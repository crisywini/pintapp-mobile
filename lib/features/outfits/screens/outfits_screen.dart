import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/outfit.dart';
import '../providers/outfit_provider.dart';
import '../widgets/outfit_card.dart';

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(outfitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Outfits')),
      body: outfits.isEmpty
          ? _EmptyState()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: outfits.length,
              itemBuilder: (_, i) {
                final outfit = outfits[i];
                final items = ref.watch(outfitItemsProvider(outfit.id));
                return OutfitCard(
                  outfit: outfit,
                  items: items,
                  onTap: () => context.push('/outfits/${outfit.id}'),
                  onLongPress: () =>
                      _showOutfitActions(context, ref, outfit),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/outfits/create'),
        tooltip: 'Create outfit',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Long-press actions ────────────────────────────────────────────────────────

void _showOutfitActions(
    BuildContext context, WidgetRef ref, Outfit outfit) {
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
            outfit.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${outfit.itemIds.length} piece${outfit.itemIds.length == 1 ? '' : 's'}',
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
              context.push('/outfits/${outfit.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(sheetCtx);
              _confirmDeleteOutfit(context, ref, outfit);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _confirmDeleteOutfit(
    BuildContext context, WidgetRef ref, Outfit outfit) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Delete "${outfit.name}"?'),
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
            ref.read(outfitProvider.notifier).deleteOutfit(outfit.id);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No outfits yet',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first pinta',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
