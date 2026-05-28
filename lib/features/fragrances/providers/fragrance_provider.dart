import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/fragrance_item.dart';
import '../../../data/repositories/fragrance_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final fragranceRepositoryProvider = Provider<FragranceRepository>(
  (_) => FragranceRepository(),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class FragranceNotifier extends Notifier<List<FragranceItem>> {
  FragranceRepository get _repo => ref.read(fragranceRepositoryProvider);

  @override
  List<FragranceItem> build() => _repo.getAll();

  Future<void> addFragrance({
    required String name,
    required String brand,
    XFile? photo,
  }) async {
    final id = const Uuid().v4();
    String? photoPath;

    if (photo != null) {
      photoPath = await _savePhoto(photo, id);
    }

    final item = FragranceItem(
      id: id,
      name: name,
      brand: brand,
      photoPath: photoPath,
    );

    await _repo.save(item);
    state = _repo.getAll();
  }

  Future<void> updateFragrance({
    required String id,
    required String name,
    required String brand,
    XFile? newPhoto,
  }) async {
    final existing = _repo.getById(id);
    if (existing == null) return;

    String? photoPath = existing.photoPath;

    if (newPhoto != null) {
      if (existing.photoPath != null) {
        final old = File(existing.photoPath!);
        if (await old.exists()) await old.delete();
      }
      photoPath = await _savePhoto(newPhoto, id);
    }

    final updated = existing.copyWith(
      name: name,
      brand: brand,
      photoPath: photoPath,
    );

    await _repo.save(updated);
    state = _repo.getAll();
  }

  Future<void> deleteFragrance(String id) async {
    final item = _repo.getById(id);
    if (item?.photoPath != null) {
      final file = File(item!.photoPath!);
      if (await file.exists()) await file.delete();
    }
    await _repo.delete(id);
    state = _repo.getAll();
  }

  Future<String> _savePhoto(XFile photo, String itemId) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'fragrance_photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final ext = p.extension(photo.path);
    final dest = p.join(photosDir.path, '$itemId$ext');
    await File(photo.path).copy(dest);
    return dest;
  }
}

final fragranceProvider =
    NotifierProvider<FragranceNotifier, List<FragranceItem>>(
        FragranceNotifier.new);
