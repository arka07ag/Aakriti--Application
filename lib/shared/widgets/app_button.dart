import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

enum AppButtonVariant { primary, secondary, inverted, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.onPressed,
    this.fullWidth = true,
    this.width,
  });

  final String label;
  final AppButtonVariant variant;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final double? width;

  // ---------------------------------------------------------------------
  // COLORS (unchanged from your original — pulled from AppColors)
  // ---------------------------------------------------------------------
  Color get _bg => switch (variant) {
    AppButtonVariant.primary => const Color.fromARGB(255, 218, 208, 58),
    AppButtonVariant.secondary => AppColors.tertiary,
    AppButtonVariant.inverted => const Color.fromARGB(255, 198, 173, 74),
    AppButtonVariant.outlined => const Color.fromARGB(0, 175, 185, 68),
  };

  Color get _fg => switch (variant) {
    AppButtonVariant.primary => Colors.white,
    AppButtonVariant.secondary => AppColors.textPrimary,
    AppButtonVariant.inverted => Colors.white,
    AppButtonVariant.outlined => AppColors.textPrimary,
  };

  // ---------------------------------------------------------------------
  // SHAPE / SIZING
  // ---------------------------------------------------------------------

  static const double _borderRadius = 24;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );

  Widget _buildLabel() {
    final ic = icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ic != null) ...[Icon(ic, size: 18), const SizedBox(width: 8)],
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = variant == AppButtonVariant.outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.neutral),
              padding: _padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
            ),
            child: _buildLabel(),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _bg,
              foregroundColor: _fg,
              padding: _padding,
              elevation: 0, // flat button, no drop shadow — matches reference
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
            ),
            child: _buildLabel(),
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
