import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/new_splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HgmFlutterApp());
}

class HgmFlutterApp extends StatelessWidget {
  const HgmFlutterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'हर घर मुनगा',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      // Define named routes for better navigation
      routes: {
        '/splash': (context) => const SplashScreen(),
      },
      // Add support for Hindi and English
      supportedLocales: const [
        Locale('hi', 'IN'), // Hindi
        Locale('en', 'US'), // English
      ],
    );
  }
}
