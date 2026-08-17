import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_colors.dart';
import '../services/stock_notification_center.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title = 'Good morning, Admin'});

  // Kept for backwards compatibility (any screen still passing a custom
  // title), but it's no longer shown — the app bar now always shows the
  // Aakriti logo + wordmark instead of a greeting.
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showAlertsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _StockAlertsSheet(),
    ).whenComplete(() {
      // Mark everything read once the panel is dismissed, so the badge
      // clears after the user has actually seen the list.
      StockNotificationCenter.instance.markAllRead();
    });
  }

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
          // Same font as the splash screen wordmark (Pirata One), so the
          // "AAKRITI" text matches everywhere the logo appears.
          Text(
            'AAKRITI',
            style: GoogleFonts.pirataOne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        ListenableBuilder(
          listenable: StockNotificationCenter.instance,
          builder: (context, _) {
            final hasUnread = StockNotificationCenter.instance.unreadCount > 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppColors.neutral,
                  onPressed: () => _showAlertsPanel(context),
                ),
                if (hasUnread)
                  const Positioned(right: 10, top: 12, child: _UnreadDot()),
              ],
            );
          },
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

// Small red dot shown on the bell icon while there's at least one unread
// out-of-stock alert. Split out just so AppTopBar.build stays readable.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// The panel that drops down from the bell icon, listing every out-of-stock
// alert (most recent first): "{Saree} ({Colour}) is out of stock." plus how
// long ago it happened.
// ----------------------------------------------------------------------------
class _StockAlertsSheet extends StatelessWidget {
  const _StockAlertsSheet();

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: StockNotificationCenter.instance,
        builder: (context, _) {
          final alerts = StockNotificationCenter.instance.alerts;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Stock Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (alerts.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              StockNotificationCenter.instance.clear(),
                          child: const Text('Clear all'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: alerts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No stock alerts yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                              ),
                              title: Text(alert.message),
                              subtitle: Text(_timeAgo(alert.time)),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
