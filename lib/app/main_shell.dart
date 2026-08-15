import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/widgets/app_top_bar.dart';

// NOTE: OrdersPage (../features/orders/orders_page.dart) is intentionally
// no longer imported/shown here — the "Orders" bottom-nav tab was replaced
// with "Search" (see _BottomNav._items below). orders_page.dart itself is
// left completely untouched on disk in case it's wired back in later.

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Bottom nav highlight index: 0 = Dashboard, 1 = Search, 2 = Settings.
  int _navIndex = 0;

  // Shared with DashboardPage. Flipping this to true is what actually
  // reveals its search bar (with a slide-down animation) — the Search tab
  // doesn't have a page of its own, it just jumps to Dashboard and opens
  // this.
  final ValueNotifier<bool> _searchVisible = ValueNotifier(false);

  late final List<Widget> _pages = [
    DashboardPage(searchVisible: _searchVisible),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _searchVisible.addListener(_onSearchVisibleChanged);
  }

  // Keeps the bottom nav's highlighted tab in sync if the search panel
  // gets closed from inside DashboardPage itself (its own X button), not
  // just when tapping a different bottom-nav tab.
  void _onSearchVisibleChanged() {
    if (!_searchVisible.value && _navIndex == 1) {
      setState(() => _navIndex = 0);
    }
  }

  @override
  void dispose() {
    _searchVisible.removeListener(_onSearchVisibleChanged);
    _searchVisible.dispose();
    super.dispose();
  }

  // Search (nav index 1) has no page of its own — it shows the Dashboard
  // page underneath the open search panel. Settings (nav index 2) maps to
  // _pages[1].
  int get _pageIndex => _navIndex == 2 ? 1 : 0;

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
    _searchVisible.value = i == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: _BottomNav(index: _navIndex, onTap: _onNavTap),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const List<(IconData, String)> _items = [
    (Icons.grid_view_rounded, 'Dashboard'),
    (Icons.search, 'Search'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E4E0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == index;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      size: 22,
                      color: active
                          ? AppColors.neutral
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? AppColors.neutral
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
