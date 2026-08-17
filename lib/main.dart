import 'package:flutter/material.dart';

import 'features/splash/aakriti_splash_screen.dart';
import 'app/main_shell.dart';
import 'app/app_theme.dart';
import 'shared/services/stock_notification_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Needed before calling into plugins (flutter_local_notifications) prior
  // to runApp().
  WidgetsFlutterBinding.ensureInitialized();
  // Sets up the notification channel and asks for permission (Android 13+ /
  // iOS) so out-of-stock alerts can actually reach the system tray.
  await StockNotificationService.init();
  runApp(const AakritiApp());
}

class AakritiApp extends StatelessWidget {
  const AakritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      home: AakritiSplashScreen(
        onFinished: () {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
        },
      ),
    );
  }
}
