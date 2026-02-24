import 'package:flutter/material.dart';

class AppTheme {
  // Define custom colors if needed
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPinkDark = Color(0xFFC2185B);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPink,
      brightness: Brightness.light,
      primary: primaryPink,
      secondary: const Color(0xFFFF4081),
      surface: Colors.white,
      onSurface: const Color(0xFF333333),
    ),
    scaffoldBackgroundColor: const Color(0xFFFCE4EC), // Light pink background
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryPink),
      titleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF333333)),
      bodyMedium: TextStyle(color: Color(0xFF333333)),
      titleLarge: TextStyle(
        color: Color(0xFF333333),
        fontWeight: FontWeight.bold,
      ),
    ),
    dividerColor: Colors.grey.shade200,
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPink,
      brightness: Brightness.dark,
      primary: primaryPink,
      secondary: const Color(0xFFFF4081),
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFEEEEEE),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
    cardColor: const Color(0xFF2C2C2C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFEEEEEE)),
      bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    dividerColor: Colors.grey.shade800,
    // Customize other components for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
    ),
  );
}
