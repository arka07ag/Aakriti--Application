import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

enum AppBadgeTone { solid, gold, lavender, neutral, success, danger }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.solid,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.solid => (AppColors.primary, Colors.white),
      AppBadgeTone.gold => (const Color(0x40C5A059), const Color(0xFF7A5F23)),
      AppBadgeTone.lavender => (AppColors.tertiary, AppColors.primary),
      AppBadgeTone.neutral => (
        const Color(0x142D2D2D),
        AppColors.textSecondary,
      ),
      AppBadgeTone.success => (const Color(0x1F2E7D32), AppColors.success),
      AppBadgeTone.danger => (const Color(0x1FB3261E), AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
