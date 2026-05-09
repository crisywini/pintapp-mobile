import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/outfit_provider.dart';

class OutfitDetailScreen extends ConsumerWidget {
  final String outfitId;
  const OutfitDetailScreen({super.key, required this.outfitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(outfitProvider);
    final outfit = outfits.where((o) => o.id == outfitId).firstOrNull;

    if (outfit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Outfit not found')),
      );
    }

    final items = sortByCategoryOrder(ref.watch(outfitItemsProvider(outfitId)));

    return Scaffold(
      appBar: AppBar(
        title: Text(outfit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No items in this outfit'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = items[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Photo
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: item.photoPath != null
                              ? Image.file(
                                  File(item.photoPath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.checkroom_outlined),
                                ),
                        ),
                      ),

                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.color} · ${item.occasion}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete outfit?'),
        content: const Text('The individual items won\'t be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(outfitProvider.notifier).deleteOutfit(outfitId);
      if (context.mounted) context.pop();
    }
  }
}
