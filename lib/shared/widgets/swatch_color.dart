// ============================================================================
// swatch_color.dart
// Turns a variant's colorCode ("#800000") or colorName ("Maroon") into an
// actual Flutter Color for swatches/dots. Shared by any screen that shows
// colour chips (product detail page, dashboard cards, etc.) so they all
// resolve colours the same way.
// ============================================================================

import 'package:flutter/material.dart';

Color swatchColorFor(String colorCode, String colorName) {
  if (colorCode.trim().isNotEmpty) {
    final hex = colorCode.trim().replaceFirst('#', '');
    final full = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(full, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  const map = {
    'red': Colors.red,
    'pink': Color(0xFFD6336C),
    'maroon': Color(0xFF800000),
    'purple': Colors.purple,
    'blue': Colors.blue,
    'navy': Color(0xFF1B1F5C),
    'teal': Colors.teal,
    'green': Colors.green,
    'yellow': Colors.amber,
    'gold': Color(0xFFC9A227),
    'orange': Colors.deepOrange,
    'black': Colors.black,
    'white': Colors.white,
    'cream': Color(0xFFFAF3E8),
    'silver': Color(0xFFC0C0C0),
    'grey': Colors.grey,
    'gray': Colors.grey,
  };
  return map[colorName.trim().toLowerCase()] ?? Colors.grey.shade400;
}