import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title = 'Good morning, Admin'});

  // Kept for backwards compatibility (any screen still passing a custom
  // title), but it's no longer shown — the app bar now always shows the
  // Aakriti logo + wordmark instead of a greeting.
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        color: AppColors.primary,
        onPressed: () {},
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/aakriti_logo.png',
            height: 32,
            width: 32,
            fit: BoxFit.contain,
            // Source PNG is 1134x1387 — plenty of resolution. Explicit
            // cache dimensions (scaled for typical device pixel ratios)
            // stop Flutter from decoding it at a tiny/blurry size, and
            // FilterQuality.high keeps the downscale crisp.
            cacheWidth: 128,
            cacheHeight: 128,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 8),
          // Bold blackletter Google Font — closer match to the thick,
          // sharp-serif "AAKRITI" wordmark strokes than the thinner
          // Maguntia style used before.
          Text(
            'AAKRITI',
            style: GoogleFonts.unifrakturCook(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.neutral,
              onPressed: () {},
            ),
            Positioned(
              right: 10,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.tertiary,
            child: const Icon(Icons.person, size: 18, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
