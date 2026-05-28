import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'data/models/clothing_item.dart';
import 'data/models/fragrance_item.dart';
import 'data/models/outfit.dart';
import 'data/services/persistence_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialise Hive at the app documents directory.
  //    This path survives app updates on both iOS and Android.
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // 2. Register type adapters before opening any box.
  Hive.registerAdapter(ClothingItemAdapter());
  Hive.registerAdapter(OutfitAdapter());
  Hive.registerAdapter(FragranceItemAdapter());

  // 3. Open persistent boxes.
  await Hive.openBox<ClothingItem>(AppConstants.wardrobeBoxName);
  await Hive.openBox<Outfit>(AppConstants.outfitsBoxName);
  await Hive.openBox<FragranceItem>(AppConstants.fragrancesBoxName);

  // 4. Run schema migrations and record install metadata.
  //    Safe to call on every launch — only acts when the stored schema
  //    version is lower than PersistenceService.currentSchemaVersion.
  await PersistenceService.init();

  runApp(const ProviderScope(child: PintApp()));
}
