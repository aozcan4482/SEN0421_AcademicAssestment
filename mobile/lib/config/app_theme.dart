import 'package:material_ui/material_ui.dart';

/// Colours and theme shared by every screen (from the WP-01 prototype).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD31018);
  static const Color text = Color(0xFF4A4A49);
  static const Color background = Color(0xFFF5F5F7);
  static const Color success = Color(0xFF2ECC71);
  static const Color pending = Color(0xFFFF6B35);
  static const Color locked = Color(0xFF7F8C8D);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
