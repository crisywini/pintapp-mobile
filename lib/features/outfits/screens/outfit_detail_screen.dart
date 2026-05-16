import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/outfit_provider.dart';

class OutfitDetailScreen extends ConsumerStatefulWidget {
  final String outfitId;
  const OutfitDetailScreen({super.key, required this.outfitId});

  @override
  ConsumerState<OutfitDetailScreen> createState() =>
      _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends ConsumerState<OutfitDetailScreen> {
  int _photoPage = 0;

  @override
  Widget build(BuildContext context) {
    final outfits = ref.watch(outfitProvider);
    final outfit =
        outfits.where((o) => o.id == widget.outfitId).firstOrNull;

    if (outfit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Outfit not found')),
      );
    }

    final items =
        sortByCategoryOrder(ref.watch(outfitItemsProvider(widget.outfitId)));
    final photoCount = outfit.photoPaths.length;

    return Scaffold(
      // Transparent appBar so it floats over the full-bleed photo
      extendBodyBehindAppBar: photoCount > 0,
      appBar: AppBar(
        backgroundColor: photoCount > 0 ? Colors.transparent : null,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: photoCount > 0 ? Colors.white : null,
        title: photoCount > 0 ? null : Text(outfit.name),
        actions: [
          if (photoCount > 0) ...[
            // Semi-transparent icon buttons over the photo
            _GlassIconButton(
              icon: Icons.edit_outlined,
              onPressed: () =>
                  context.push('/outfits/${widget.outfitId}/edit'),
            ),
            _GlassIconButton(
              icon: Icons.delete_outline,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/outfits/${widget.outfitId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Full-bleed outfit photos ─────────────────────────────────────
          if (photoCount > 0) ...[
            SizedBox(
              // Portrait ratio: just taller than the screen width
              height: MediaQuery.of(context).size.width * 1.25,
              child: Stack(
                children: [
                  // PageView fills the full box
                  PageView.builder(
                    itemCount: photoCount,
                    onPageChanged: (i) => setState(() => _photoPage = i),
                    itemBuilder: (_, i) => Image.file(
                      File(outfit.photoPaths[i]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),

                  // Outfit name + dot indicators at the bottom of the photo
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            outfit.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (photoCount > 1) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(photoCount, (i) {
                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 5),
                                  width: i == _photoPage ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _photoPage
                                        ? Colors.white
                                        : Colors.white38,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Items & actions (padded section) ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show title here when there's no photo
                if (photoCount == 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    outfit.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                ],

                if (items.isEmpty)
                  const Center(child: Text('No items in this outfit'))
                else ...[
                  Text(
                    'Items',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
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
                              // Item photo — significantly larger
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16),
                                ),
                                child: SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: item.photoPath != null
                                      ? Image.file(
                                          File(item.photoPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                              Icons.checkroom_outlined,
                                              size: 36),
                                        ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.color} · ${item.occasion}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: () =>
                      context.push('/outfits/${widget.outfitId}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Outfit'),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                  label: Text(
                    'Delete Outfit',
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
              ],
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
        title: const Text('Delete outfit?'),
        content: const Text("The individual items won't be affected."),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(outfitProvider.notifier)
          .deleteOutfit(widget.outfitId);
      if (context.mounted) context.pop();
    }
  }
}

// ── Frosted-glass icon button (floats over the photo) ────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
