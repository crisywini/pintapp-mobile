import 'package:shared_preferences/shared_preferences.dart';

/// Manages schema versioning and migrations for PintApp's local data.
///
/// ## How Hive schema changes work
///
/// Hive is safe to extend as long as you follow these rules:
///   ✅ ADD new fields: use the next available @HiveField index
///       - ClothingItem: next index is 6
///       - Outfit:       next index is 5
///   ❌ NEVER reuse or renumber existing @HiveField indices
///   ❌ NEVER change the Dart type of an existing @HiveField
///   ❌ NEVER remove a @HiveField (mark deprecated instead)
///
/// When a stored record is missing a new nullable field, Hive returns null
/// automatically — no migration is needed for additive changes.
/// Only destructive changes (type renames, removals) require a migration.
///
/// ## Adding a migration
///
/// 1. Bump [currentSchemaVersion].
/// 2. Add an `if (from < N)` block inside [_runMigrations].
/// 3. Write the migration logic (read old box, transform, write back).
///
/// ## Schema version history
///
/// | Version | App version | Changes                                   |
/// |---------|-------------|-------------------------------------------|
/// | 1       | 1.0.0       | Initial — ClothingItem(0-5), Outfit(0-4)  |
class PersistenceService {
  static const int currentSchemaVersion = 1;

  static const String _schemaVersionKey = 'schema_version';
  static const String _firstInstallKey = 'first_install_date';

  /// Call this in main() after Hive boxes are open, before runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final storedVersion = prefs.getInt(_schemaVersionKey) ?? 0;

    if (storedVersion < currentSchemaVersion) {
      await _runMigrations(from: storedVersion, prefs: prefs);
      await prefs.setInt(_schemaVersionKey, currentSchemaVersion);
    }

    if (!prefs.containsKey(_firstInstallKey)) {
      await prefs.setString(
        _firstInstallKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  static Future<void> _runMigrations({
    required int from,
    required SharedPreferences prefs,
  }) async {
    if (from < 1) {
      // v0 → v1: Initial schema, nothing to transform.
      // Existing Hive data is already in v1 format.
      // Nullable fields added to Outfit (photoPaths, outfitType) are handled
      // automatically by Hive when reading older records.
    }

    // Template for future migrations — uncomment and implement as needed:
    //
    // if (from < 2) {
    //   // v1 → v2: Example — rename occasion 'Sport' → 'Athletic'
    //   final box = Hive.box<ClothingItem>(AppConstants.wardrobeBoxName);
    //   for (final item in box.values.toList()) {
    //     if (item.occasion == 'Sport') {
    //       await box.put(item.id, item.copyWith(occasion: 'Athletic'));
    //     }
    //   }
    // }
    //
    // if (from < 3) {
    //   // v2 → v3: ...
    // }
  }

  /// Returns the date the app was first installed on this device.
  static Future<DateTime?> firstInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_firstInstallKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Returns the schema version currently stored on disk.
  static Future<int> storedSchemaVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_schemaVersionKey) ?? 0;
  }
}
