import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Light Theme Colors
  static const Color primaryLight = Color(0xFF6366F1); // Indigo
  static const Color secondaryLight = Color(0xFF10B981); // Emerald
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color successLight = Color(0xFF10B981);
  static const Color warningLight = Color(0xFFF59E0B);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color secondaryDark = Color(0xFF34D399);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color errorDark = Color(0xFFF87171);
  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);

  // Shadow colors
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> hardShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        background: backgroundLight,
        surface: surfaceLight,
        error: errorLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: surfaceLight,
        foregroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        color: surfaceLight,
        shadowColor: Colors.black.withOpacity(0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: primaryLight.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight.withOpacity(0.1),
        selectedColor: primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorLight, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        background: backgroundDark,
        surface: surfaceDark,
        error: errorDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        color: surfaceDark,
        shadowColor: Colors.black54,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryDark, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryDark.withOpacity(0.2),
        selectedColor: primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorDark, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorDark, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}
