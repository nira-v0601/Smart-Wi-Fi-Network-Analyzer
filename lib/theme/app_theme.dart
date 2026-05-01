import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0F19); // Deep Navy/Charcoal
  static const Color surfaceContainerLow = Color(0xFF111827);
  static const Color surfaceContainer = Color(0xFF1F2937);
  static const Color surfaceVariant = Color(0xFF374151);
  
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF6366F1); // Deep Indigo
  static const Color tertiary = Color(0xFF10B981); // Emerald Green
  
  static const Color error = Color(0xFFEF4444); // Red
  
  static const Color onSurface = Color(0xFFF9FAFB);
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);

  // Layout Constants
  static const double padding = 16.0;
  static const double cardSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double borderRadius = 20.0;

  // Global Card Decoration
  static BoxDecoration cardDecoration([Color glowColor = primary]) {
    return BoxDecoration(
      color: surfaceContainerLow.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.05),
          blurRadius: 15,
          spreadRadius: 2,
        )
      ],
    );
  }

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
        displayLarge: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.outfit(color: onSurface, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: onSurface),
        bodyMedium: GoogleFonts.inter(color: onSurface),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant),
        labelLarge: GoogleFonts.outfit(color: onSurfaceVariant, fontWeight: FontWeight.bold),
        labelMedium: GoogleFonts.outfit(color: onSurfaceVariant, fontWeight: FontWeight.bold),
        labelSmall: GoogleFonts.outfit(color: onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
