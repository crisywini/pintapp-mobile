import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/fragrance_item.dart';
import '../providers/fragrance_provider.dart';

class FragrancesScreen extends ConsumerWidget {
  const FragrancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fragrances = ref.watch(fragranceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fragancias'),
      ),
      body: fragrances.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: fragrances.length,
              itemBuilder: (_, i) => _FragranceCard(
                fragrance: fragrances[i],
                onLongPress: () =>
                    _showFragranceActions(context, ref, fragrances[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/fragrances/add'),
        tooltip: 'Añadir fragancia',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Fragrance card ────────────────────────────────────────────────────────────

class _FragranceCard extends StatelessWidget {
  final FragranceItem fragrance;
  final VoidCallback onLongPress;

  const _FragranceCard({
    required this.fragrance,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: fragrance.photoPath != null
                    ? Image.file(
                        File(fragrance.photoPath!),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.water_drop_outlined,
                            size: 28,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.water_drop_outlined,
                          size: 28,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fragrance.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fragrance.brand,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Long-press actions ────────────────────────────────────────────────────────

void _showFragranceActions(
    BuildContext context, WidgetRef ref, FragranceItem fragrance) {
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
            fragrance.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            fragrance.brand,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(sheetCtx);
              context.push('/fragrances/${fragrance.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(sheetCtx);
              _confirmDelete(context, ref, fragrance);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _confirmDelete(
    BuildContext context, WidgetRef ref, FragranceItem fragrance) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Eliminar "${fragrance.name}"?'),
      content: const Text('Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(dialogCtx);
            ref
                .read(fragranceProvider.notifier)
                .deleteFragrance(fragrance.id);
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tu colección está vacía',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para añadir tu primera fragancia',
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
