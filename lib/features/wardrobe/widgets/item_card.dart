import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clothing_item.dart';

class ItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  Color _colorValue() {
    return AppConstants.colors
        .firstWhere(
          (c) => c.name == item.color,
          orElse: () => AppConstants.colors.first,
        )
        .value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            // Photo area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.photoPath != null
                    ? Image.file(
                        File(item.photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : _PlaceholderPhoto(color: _colorValue()),
              ),
            ),

            // Info area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorValue(),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.occasion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _PlaceholderPhoto extends StatelessWidget {
  final Color color;
  const _PlaceholderPhoto({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withAlpha(30),
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 40,
          color: color.withAlpha(120),
        ),
      ),
    );
  }
}
