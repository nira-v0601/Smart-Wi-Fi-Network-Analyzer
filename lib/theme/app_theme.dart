import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1919);
  static const Color surfaceVariant = Color(0xFF262626);
  
  static const Color primary = Color(0xFFC799FF);
  static const Color secondary = Color(0xFF4AF8E3);
  static const Color tertiary = Color(0xFFF3FFCA);
  
  static const Color error = Color(0xFFFF6E84);
  
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFADAAAA);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surfaceContainer,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        onPrimary: Color(0xFF440080),
        onSecondary: Color(0xFF005B51),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.spaceGrotesk(color: onSurface, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: onSurface),
        bodyMedium: GoogleFonts.inter(color: onSurface),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant),
        labelLarge: GoogleFonts.spaceGrotesk(color: onSurfaceVariant, fontWeight: FontWeight.bold),
        labelMedium: GoogleFonts.spaceGrotesk(color: onSurfaceVariant, fontWeight: FontWeight.bold),
        labelSmall: GoogleFonts.spaceGrotesk(color: onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLow.withValues(alpha: 0.9),
        unselectedItemColor: onSurfaceVariant.withValues(alpha: 0.7),
        selectedItemColor: primary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
