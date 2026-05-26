import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';

/// Exports all user data to versioned JSON files as a safety net against
/// data loss (e.g. corrupted Hive boxes, accidental uninstall).
///
/// ## What is backed up
///   - All [ClothingItem] records (name, category, color, occasion, photoPath)
///   - All [Outfit] records (name, itemIds, photoPaths, outfitType)
///
/// ## What is NOT backed up
///   Photo files (wardrobe_photos/, outfit_photos/) are large binary files.
///   The backup stores the original file paths so photos can be verified
///   manually if needed. For full photo backup use the device's iCloud /
///   Google Photos backup.
///
/// ## Backup location
///   {AppDocuments}/pintapp_backups/pintapp_backup_{timestamp}.json
///
/// ## Retention
///   Only the 5 most recent backups are kept; older ones are deleted
///   automatically after each export.
class BackupService {
  static const String _backupDirName = 'pintapp_backups';
  static const int _backupFormatVersion = 1;
  static const int _maxBackupsToKeep = 5;

  // ── Export ──────────────────────────────────────────────────────────────

  /// Exports all wardrobe and outfit data to a JSON file.
  ///
  /// Returns the absolute path of the created backup file.
  static Future<String> exportToJson() async {
    final wardrobeBox = Hive.box<ClothingItem>(AppConstants.wardrobeBoxName);
    final outfitsBox = Hive.box<Outfit>(AppConstants.outfitsBoxName);

    final payload = {
      'backupFormatVersion': _backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': wardrobeBox.length,
      'outfitCount': outfitsBox.length,
      'wardrobe': [
        for (final item in wardrobeBox.values)
          {
            'id': item.id,
            'name': item.name,
            'category': item.category,
            'color': item.color,
            'photoPath': item.photoPath,
            'occasion': item.occasion,
          },
      ],
      'outfits': [
        for (final outfit in outfitsBox.values)
          {
            'id': outfit.id,
            'name': outfit.name,
            'itemIds': outfit.itemIds,
            'photoPaths': outfit.photoPaths,
            'outfitType': outfit.outfitType,
          },
      ],
    };

    final file = await _createBackupFile();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    await _pruneOldBackups();

    return file.path;
  }

  // ── Query ────────────────────────────────────────────────────────────────

  /// Returns all existing backup files, newest first.
  static Future<List<File>> listBackups() async {
    final dir = await _backupDirectory();
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files;
  }

  /// Reads and parses a backup file into a raw Map for inspection or restore.
  static Future<Map<String, dynamic>> readBackup(File file) async {
    final raw = await file.readAsString();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Future<File> _createBackupFile() async {
    final dir = await _backupDirectory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File('${dir.path}/pintapp_backup_$timestamp.json');
  }

  static Future<Directory> _backupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_backupDirName');
  }

  static Future<void> _pruneOldBackups() async {
    final backups = await listBackups();
    if (backups.length > _maxBackupsToKeep) {
      for (final old in backups.skip(_maxBackupsToKeep)) {
        await old.delete();
      }
    }
  }
}
