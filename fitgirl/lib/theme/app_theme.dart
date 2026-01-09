import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom theme matching the HTML mockup design
/// Dark theme with Space Grotesk and Noto Sans fonts
/// Primary color: #137fec (blue)
class AppTheme {
  // Primary Colors
  static const primary = Color(0xFF137FEC);
  static const primaryDark = Color(0xFF0B6FD8);
  
  // Background Colors
  static const backgroundDark = Color(0xFF101922);
  static const surfaceDark = Color(0xFF1A2632);
  static const surfaceHover = Color(0xFF233648);
  static const surfaceLight = Color(0xFF253A4A);
  static const borderColor = Color(0xFF2A3B4D);
  
  // Slate Color Palette
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  
  // Status Colors
  static const statusOnline = Color(0xFF10B981);   // emerald-500
  static const statusOffline = Color(0xFFEF4444);  // red-500
  static const statusWarning = Color(0xFFEAB308);  // yellow-500
  static const statusHot = Color(0xFFF59E0B);      // amber-500
  static const statusError = Color(0xFFEF4444);    // red-500 (same as offline)
  static const error = statusError;
  
  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'SpaceGrotesk',
      
      // Disable Material 3
      useMaterial3: false,
      
      // Custom color scheme (no seed generation)
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surfaceDark,
        background: backgroundDark,
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        error: statusOffline,
      ),
      
      // Disable elevation overlays
      applyElevationOverlayColor: false,
      
      // Card theme - no elevation, custom borders
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Custom text theme with Space Grotesk and Noto Sans
      textTheme: TextTheme(
        // Display styles - Space Grotesk
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
        
        // Headline styles - Space Grotesk
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        
        // Body styles - Noto Sans
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: slate400,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: slate500,
        ),
        
        // Label styles - Space Grotesk
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: slate400,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: slate500,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: slate400,
        size: 24,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  // Custom shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get primaryButtonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
