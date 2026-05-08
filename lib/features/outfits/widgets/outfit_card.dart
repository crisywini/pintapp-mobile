import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/models/clothing_item.dart';
import '../../../data/models/outfit.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final List<ClothingItem> items;
  final VoidCallback onTap;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = items.where((i) => i.photoPath != null).take(4).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo mosaic
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _PhotoMosaic(photos: photos),
              ),
            ),

            // Name + item count
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${outfit.itemIds.length} piece${outfit.itemIds.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoMosaic extends StatelessWidget {
  final List<ClothingItem> photos;
  const _PhotoMosaic({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(Icons.style_outlined, size: 48, color: Colors.grey[300]),
        ),
      );
    }

    if (photos.length == 1) {
      return Image.file(File(photos[0].photoPath!), fit: BoxFit.cover, width: double.infinity);
    }

    if (photos.length == 2) {
      return Row(
        children: photos
            .map((i) => Expanded(
                  child: Image.file(File(i.photoPath!), fit: BoxFit.cover, height: double.infinity),
                ))
            .toList(),
      );
    }

    // 3 or 4: left half + right column
    return Row(
      children: [
        Expanded(
          child: Image.file(File(photos[0].photoPath!), fit: BoxFit.cover, height: double.infinity),
        ),
        const SizedBox(width: 1),
        Expanded(
          child: Column(
            children: [
              for (int i = 1; i < photos.length && i < 4; i++) ...[
                if (i > 1) const SizedBox(height: 1),
                Expanded(
                  child: Image.file(File(photos[i].photoPath!), fit: BoxFit.cover, width: double.infinity),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
