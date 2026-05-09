import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> categories = [
    'Tops',
    'Bottoms',
    'Shoes',
    'Outerwear',
    'Accessories',
  ];

  static const List<String> occasions = [
    'Casual',
    'Work',
    'Formal',
    'Sport',
  ];

  static const List<AppColor> colors = [
    // Default: covers multicolored, patterned, or "doesn't apply" items
    AppColor(name: 'Multi', value: Color(0xFFE0E0E0), isMulti: true),
    AppColor(name: 'White', value: Color(0xFFFFFFFF)),
    AppColor(name: 'Black', value: Color(0xFF1A1A1A)),
    AppColor(name: 'Gray', value: Color(0xFF9E9E9E)),
    AppColor(name: 'Navy', value: Color(0xFF1A237E)),
    AppColor(name: 'Blue', value: Color(0xFF1565C0)),
    AppColor(name: 'Green', value: Color(0xFF2E7D32)),
    AppColor(name: 'Red', value: Color(0xFFC62828)),
    AppColor(name: 'Pink', value: Color(0xFFEC407A)),
    AppColor(name: 'Yellow', value: Color(0xFFFDD835)),
    AppColor(name: 'Orange', value: Color(0xFFEF6C00)),
    AppColor(name: 'Brown', value: Color(0xFF5D4037)),
    AppColor(name: 'Beige', value: Color(0xFFF5F0E8)),
  ];

  static const String wardrobeBoxName = 'wardrobe';
  static const String outfitsBoxName = 'outfits';
}

class AppColor {
  final String name;
  final Color value;
  final bool isMulti;

  const AppColor({required this.name, required this.value, this.isMulti = false});
}
