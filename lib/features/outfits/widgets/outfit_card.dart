import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/clothing_item.dart';
import '../../../data/models/outfit.dart';

class OutfitCard extends StatefulWidget {
  final Outfit outfit;
  final List<ClothingItem> items;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.items,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemPhotos =
        widget.items.where((i) => i.photoPath != null).take(4).toList();

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress?.call();
      },
      onLongPressStart: (_) => setState(() => _pressed = true),
      onLongPressEnd: (_) => setState(() => _pressed = false),
      onLongPressCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
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
              // Outfit photo takes priority; fall back to item collage
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: widget.outfit.photoPaths.isNotEmpty
                      ? Image.file(
                          File(widget.outfit.photoPaths.first),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) =>
                              _PhotoMosaic(photos: itemPhotos),
                        )
                      : _PhotoMosaic(photos: itemPhotos),
                ),
              ),

              // Name + item count
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.outfit.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.outfit.itemIds.length} piece${widget.outfit.itemIds.length == 1 ? '' : 's'}',
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
      return Image.file(
        File(photos[0].photoPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) =>
            Container(color: Colors.grey[100]),
      );
    }

    if (photos.length == 2) {
      return Row(
        children: photos
            .map((i) => Expanded(
                  child: Image.file(
                    File(i.photoPath!),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, _, _) =>
                        Container(color: Colors.grey[100]),
                  ),
                ))
            .toList(),
      );
    }

    // 3 or 4: left half + right column
    return Row(
      children: [
        Expanded(
          child: Image.file(
            File(photos[0].photoPath!),
            fit: BoxFit.cover,
            height: double.infinity,
            errorBuilder: (_, _, _) =>
                Container(color: Colors.grey[100]),
          ),
        ),
        const SizedBox(width: 1),
        Expanded(
          child: Column(
            children: [
              for (int i = 1; i < photos.length && i < 4; i++) ...[
                if (i > 1) const SizedBox(height: 1),
                Expanded(
                  child: Image.file(
                    File(photos[i].photoPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) =>
                        Container(color: Colors.grey[100]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
