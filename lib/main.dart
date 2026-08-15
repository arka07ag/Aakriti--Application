import 'package:flutter/material.dart';

import 'features/splash/aakriti_splash_screen.dart';
import 'app/main_shell.dart';
import 'app/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
