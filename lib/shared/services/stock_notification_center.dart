// ============================================================================
// stock_notification_center.dart
// In-app notification list that powers the bell icon in AppTopBar:
//   - Scans the saree list for any colour variant with quantity == 0.
//   - The first time a colour is seen at 0 stock, it (a) records a
//     StockAlert the bell's dropdown can show, and (b) fires a real
//     system/device notification via StockNotificationService.
//   - If that colour is later restocked and goes to 0 again, it alerts
//     again — but while it stays at 0 it won't spam duplicate alerts.
//
// This is a plain singleton (ChangeNotifier) rather than a full state-
// management setup, matching the rest of the app's lightweight style (see
// the ValueNotifier used for search visibility in MainShell/DashboardPage).
// ============================================================================

import 'package:flutter/foundation.dart';

import '../widgets/saree.dart';
import 'stock_notification_service.dart';

class StockAlert {
  final String id;
  final String sareeId;
  final String sareeName;
  final String colorName;
  final DateTime time;
  bool read;

  StockAlert({
    required this.id,
    required this.sareeId,
    required this.sareeName,
    required this.colorName,
    required this.time,
    this.read = false,
  });

  String get message => '$sareeName ($colorName) is out of stock.';
}

class StockNotificationCenter extends ChangeNotifier {
  StockNotificationCenter._();

  static final StockNotificationCenter instance = StockNotificationCenter._();

  final List<StockAlert> _alerts = [];

  // Tracks which "saree|colour" combinations are CURRENTLY known to be out
  // of stock, so re-scanning the same unchanged list (e.g. every rebuild)
  // doesn't create duplicate alerts. A key is removed once that variant is
  // restocked, so going out of stock again later re-triggers an alert.
  final Set<String> _currentlyOutOfStock = {};

  List<StockAlert> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.read).length;

  String _keyFor(String sareeId, String colorName) => '$sareeId|$colorName';

  /// Call this any time the saree list is loaded or changes (initial load,
  /// after adding/editing a saree, after restocking, etc.). It figures out
  /// which colour variants are newly out of stock and raises alerts only
  /// for those.
  void syncFromSarees(List<Saree> sarees) {
    final seenKeys = <String>{};

    for (final saree in sarees) {
      for (final variant in saree.variants) {
        final key = _keyFor(saree.id, variant.colorName);

        if (variant.quantity <= 0) {
          seenKeys.add(key);
          if (!_currentlyOutOfStock.contains(key)) {
            _currentlyOutOfStock.add(key);
            _raiseAlert(
              sareeId: saree.id,
              sareeName: saree.name,
              colorName: variant.colorName,
            );
          }
        }
      }
    }

    // Anything that was out of stock before but isn't in this pass anymore
    // has been restocked (or removed) — clear it so it can alert again in
    // the future if it drops back to zero.
    _currentlyOutOfStock.removeWhere((key) => !seenKeys.contains(key));
  }

  void _raiseAlert({
    required String sareeId,
    required String sareeName,
    required String colorName,
  }) {
    _alerts.insert(
      0,
      StockAlert(
        id: '${sareeId}_${colorName}_${DateTime.now().microsecondsSinceEpoch}',
        sareeId: sareeId,
        sareeName: sareeName,
        colorName: colorName,
        time: DateTime.now(),
      ),
    );
    notifyListeners();

    // Fire the real device/system notification too.
    StockNotificationService.showOutOfStock(
      sareeId: sareeId,
      sareeName: sareeName,
      colorName: colorName,
    );
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    for (final a in _alerts) {
      a.read = true;
    }
    notifyListeners();
  }

  void clear() {
    _alerts.clear();
    notifyListeners();
  }
}
