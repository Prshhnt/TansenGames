import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/api_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiSettings.init();
  runApp(const TansenGamesApp());
}

/// Root application widget
/// Uses custom dark theme matching HTML mockup design
class TansenGamesApp extends StatelessWidget {
  const TansenGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tansen Games',
      debugShowCheckedModeBanner: false,

      // Custom dark theme (no Material 3)
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      home: const MainScreen(),
    );
  }
}
