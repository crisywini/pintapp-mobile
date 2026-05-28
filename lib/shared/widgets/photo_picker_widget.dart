import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerWidget extends StatelessWidget {
  final XFile? photo;
  final String? existingPhotoPath;
  final ValueChanged<XFile> onPicked;
  final bool hasError;

  const PhotoPickerWidget({
    super.key,
    this.photo,
    this.existingPhotoPath,
    required this.onPicked,
    this.hasError = false,
  });

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: hasError ? errorColor.withAlpha(12) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasError ? errorColor : Colors.grey[300]!,
                  width: hasError ? 1.5 : 1,
                ),
              ),
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(photo!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : existingPhotoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(existingPhotoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Foto no disponible',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: hasError ? errorColor : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add photo',
                          style: TextStyle(
                            color: hasError ? errorColor : Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'A photo is required',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: errorColor,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
