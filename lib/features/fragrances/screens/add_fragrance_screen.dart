import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/photo_picker_widget.dart';
import '../providers/fragrance_provider.dart';

class AddFragranceScreen extends ConsumerStatefulWidget {
  final String? editFragranceId;
  const AddFragranceScreen({super.key, this.editFragranceId});

  bool get isEditing => editFragranceId != null;

  @override
  ConsumerState<AddFragranceScreen> createState() => _AddFragranceScreenState();
}

class _AddFragranceScreenState extends ConsumerState<AddFragranceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();

  XFile? _photo;
  String? _existingPhotoPath;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadItem());
    }
  }

  void _loadItem() {
    final item = ref
        .read(fragranceProvider)
        .where((i) => i.id == widget.editFragranceId)
        .firstOrNull;
    if (item == null) return;

    setState(() {
      _nameController.text = item.name;
      _brandController.text = item.brand;
      _existingPhotoPath = item.photoPath;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    if (widget.isEditing) {
      await ref.read(fragranceProvider.notifier).updateFragrance(
            id: widget.editFragranceId!,
            name: _nameController.text.trim(),
            brand: _brandController.text.trim(),
            newPhoto: _photo,
          );
    } else {
      await ref.read(fragranceProvider.notifier).addFragrance(
            name: _nameController.text.trim(),
            brand: _brandController.text.trim(),
            photo: _photo,
          );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Fragancia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Fragancia' : 'Nueva Fragancia'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo picker (optional)
            PhotoPickerWidget(
              photo: _photo,
              existingPhotoPath: _existingPhotoPath,
              onPicked: (f) => setState(() => _photo = f),
            ),

            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'ej. Sauvage',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
            ),

            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                hintText: 'ej. Dior',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'La marca es obligatoria' : null,
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
