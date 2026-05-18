import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFFA855F7);
  static const purpleDark = Color(0xFF7E22CE);
  static const bg = Color(0xFF0F1115);
  static const surface = Color(0xFF1A1D24);
  static const surfaceAlt = Color(0xFF232831);
  static const textMuted = Color(0xFF9AA3B2);
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      useMaterial3: true,
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.textMuted,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
    );
  }
}

/// Branded "GenSalon" title — Gen white, Salon purple.
class BrandTitle extends StatelessWidget {
  final double size;
  const BrandTitle({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        children: const [
          TextSpan(text: 'Gen', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Salon', style: TextStyle(color: AppColors.purple)),
        ],
      ),
    );
  }
}
