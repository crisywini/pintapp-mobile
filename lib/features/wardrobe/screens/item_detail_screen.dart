import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/color_dot.dart';
import '../providers/wardrobe_provider.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wardrobeProvider);
    final item = items.where((i) => i.id == itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      );
    }

    final appColor = AppConstants.colors.firstWhere(
      (c) => c.name == item.color,
      orElse: () => AppConstants.colors.first,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Large photo header — back button only, no icons on top of photo
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: item.photoPath != null
                  ? Image.file(File(item.photoPath!), fit: BoxFit.cover)
                  : Container(
                      color: appColor.value.withAlpha(40),
                      child: Center(
                        child: Icon(
                          Icons.checkroom_outlined,
                          size: 80,
                          color: appColor.value.withAlpha(100),
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: item.category,
                  ),
                  _ColorRow(appColor: appColor, label: item.color),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Occasion',
                    value: item.occasion,
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Edit button
                  FilledButton.icon(
                    onPressed: () => context.push('/wardrobe/$itemId/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Item'),
                  ),

                  const SizedBox(height: 12),

                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                    label: Text(
                      'Delete Item',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will remove the item from your wardrobe.'),
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
      await ref.read(wardrobeProvider.notifier).deleteItem(itemId);
      if (context.mounted) context.pop();
    }
  }
}

class _ColorRow extends StatelessWidget {
  final AppColor appColor;
  final String label;
  const _ColorRow({required this.appColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ColorDot(appColor: appColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Color',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
