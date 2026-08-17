// ============================================================================
// stock_notification_service.dart
// Thin wrapper around `flutter_local_notifications` — this is the piece that
// actually pushes a notification into the phone's system tray (Android
// notification shade / iOS notification banner), as opposed to the in-app
// bell dropdown (see stock_notification_center.dart for that).
//
// Call StockNotificationService.init() once, early in main() before
// runApp(). After that, call StockNotificationService.showOutOfStock(...)
// any time a colour variant's stock hits zero.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StockNotificationService {
  StockNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Every notification channel/id needs a distinct integer on Android — we
  // derive it from the saree+colour so the SAME colour going out of stock
  // twice replaces its own earlier notification instead of piling up, while
  // different sarees/colours each get their own notification.
  static int _notificationId(String sareeId, String colorName) =>
      Object.hash(sareeId, colorName) & 0x7fffffff;

  /// Sets up the plugin and (on Android 13+ / iOS) asks the user for
  /// notification permission. Safe to call multiple times — later calls are
  /// no-ops.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+ (API 33) requires runtime permission for notifications.
    // Older Android versions and iOS handled above via the settings/init
    // calls, so this is a no-op there.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint(
        'StockNotificationService: notification permission request '
        'failed: $e',
      );
    }
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'stock_alerts', // channel id
        'Stock Alerts', // channel name shown in system settings
        channelDescription: 'Alerts when a saree colour runs out of stock.',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Pushes "Out of stock — {sareeName} ({colorName}) has no stock left."
  /// into the phone's notification tray.
  static Future<void> showOutOfStock({
    required String sareeId,
    required String sareeName,
    required String colorName,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      _notificationId(sareeId, colorName),
      'Out of stock',
      'The stock of $sareeName in $colorName colour is empty.',
      _details,
    );
  }
}
