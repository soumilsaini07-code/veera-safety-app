import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceVariant = Color(0xFF353534);
  static const Color primary = Color(0xFFDDB7FF);
  static const Color primaryContainer = Color(0xFF4B0082);
  static const Color secondary = Color(0xFFBAC3FF);
  static const Color secondaryContainer = Color(0xFF2C3EA3);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color outline = Color(0xFF978D9D);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        onSurface: onSurface,
        error: error,
        errorContainer: errorContainer,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.montserrat(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.02, color: onSurface),
        headlineLarge: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.02, color: onSurface),
        headlineMedium: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface),
        headlineSmall: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
        bodyMedium: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
        labelLarge: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: onSurface),
        labelMedium: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.0, color: outline),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: primary,
          textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // Pill shape
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: outline),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant.withValues(alpha: 0.3),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline, width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
