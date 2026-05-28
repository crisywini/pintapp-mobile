import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clothing_item.dart';
import '../../../shared/widgets/color_dot.dart';

class ItemCard extends StatefulWidget {
  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _pressed = false;

  AppColor _appColor() {
    return AppConstants.colors.firstWhere(
      (c) => c.name == widget.item.color,
      orElse: () => AppConstants.colors.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              // Photo area
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: widget.item.photoPath != null
                      ? Image.file(
                          File(widget.item.photoPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) =>
                              _PlaceholderPhoto(color: _appColor().value),
                        )
                      : _PlaceholderPhoto(color: _appColor().value),
                ),
              ),

              // Info area
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ColorDot(appColor: _appColor(), size: 10),
                        const SizedBox(width: 5),
                        Text(
                          widget.item.occasion,
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
