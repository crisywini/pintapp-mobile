import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_constants.dart';
import 'data/models/clothing_item.dart';
import 'data/models/outfit.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  Hive.registerAdapter(ClothingItemAdapter());
  Hive.registerAdapter(OutfitAdapter());

  await Hive.openBox<ClothingItem>(AppConstants.wardrobeBoxName);
  await Hive.openBox<Outfit>(AppConstants.outfitsBoxName);

  runApp(const ProviderScope(child: PintApp()));
}
