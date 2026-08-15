// ============================================================================
// app_search_field.dart
// ----------------------------------------------------------------------------
// Shared search input used across the app (Dashboard, Products, Orders, etc).
// The rounded "pill" styling (white background, gold-tinted border, grey
// hint/icon) now lives HERE instead of being re-built on every screen, so any
// screen that uses <AppSearchField /> automatically looks consistent.
//
// If you later add a central theme/colors file (e.g. lib/app/app_colors.dart),
// replace the local `_SearchFieldColors` class below with an import of that
// file so colors stay in one place across the whole app.
// ============================================================================

import 'package:flutter/material.dart';

// ----------------------------------------------------------------------------
// COLORS
// ----------------------------------------------------------------------------
// Kept local to this widget for now. These match the gold/cream theme used
// in dashboard_page.dart — if you move colors to a shared file, delete this
// class and import the shared one instead in both places.
class _SearchFieldColors {
  static const Color background = Color(0xFFFFFFFF); // field background
  static const Color border = Color(0xFFE6DCC8); // subtle gold-tinted border
  static const Color hintGrey = Color(0xFF8A8378); // hint text + search icon
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.hint = 'Search',
    this.controller,
    this.onChanged,
  });

  // Placeholder text shown when the field is empty.
  final String hint;

  // Optional controller — pass one in if the parent screen needs to read/
  // clear the search text (e.g. dashboard_page.dart does this).
  final TextEditingController? controller;

  // Callback fired every time the text changes — parent screens use this to
  // filter their lists (e.g. filtering the saree inventory list).
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Container wraps the TextField purely to give it the rounded "pill"
    // shape + border, since a plain TextField's default look is a boxy
    // underline input.
    return Container(
      decoration: BoxDecoration(
        color: _SearchFieldColors.background,
        borderRadius: BorderRadius.circular(30), // pill shape
        border: Border.all(color: _SearchFieldColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _SearchFieldColors.hintGrey),
          prefixIcon: const Icon(
            Icons.search,
            color: _SearchFieldColors.hintGrey,
          ),
          border: InputBorder.none, // remove default underline
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
