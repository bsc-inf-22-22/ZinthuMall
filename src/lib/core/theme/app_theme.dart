// =============================================================
// FILE: lib/core/theme/app_theme.dart
//
// UPDATED: Now uses google_fonts package instead of local .ttf
// files. GoogleFonts.playfairDisplay() and GoogleFonts.dmSans()
// download and cache the fonts automatically.
// =============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(); // Private constructor — no instances allowed

  // ----------------------------------------------------------
  // BRAND COLORS
  // ----------------------------------------------------------
  static const Color primaryRed    = Color(0xFFC8102E);
  static const Color accentOrange  = Color(0xFFFF8C00);
  static const Color darkBg        = Color(0xFF1A1A1A);
  static const Color surface       = Color(0xFFFAFAF8);
  static const Color cardWhite     = Color(0xFFFFFFFF);
  static const Color borderColor   = Color(0xFFEBEBEB);
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint      = Color(0xFF999999);
  static const Color successGreen  = Color(0xFF27AE60);

  // ----------------------------------------------------------
  // SPACING SCALE (base-8)
  // ----------------------------------------------------------
  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;
  static const double spaceXXL = 48.0;

  // ----------------------------------------------------------
  // BORDER RADIUS
  // ----------------------------------------------------------
  static const double radiusSM   = 8.0;
  static const double radiusMD   = 14.0;
  static const double radiusLG   = 20.0;
  static const double radiusPill = 40.0;

  // ----------------------------------------------------------
  // FONT SIZES
  // ----------------------------------------------------------
  static const double fontXS   = 10.0;
  static const double fontSM   = 12.0;
  static const double fontMD   = 14.0;
  static const double fontLG   = 16.0;
  static const double fontXL   = 20.0;
  static const double fontXXL  = 24.0;
  static const double fontHero = 32.0;

  // ----------------------------------------------------------
  // TEXT STYLES using Google Fonts
  //
  // GoogleFonts.playfairDisplay() returns a TextStyle already
  // configured with the Playfair Display font.
  // We just merge our custom size/weight/color on top.
  // ----------------------------------------------------------
  static TextStyle get headingLarge => GoogleFonts.playfairDisplay(
    fontSize: fontHero,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headingMedium => GoogleFonts.playfairDisplay(
    fontSize: fontXXL,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headingSmall => GoogleFonts.playfairDisplay(
    fontSize: fontXL,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: fontMD,
    color: textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
    fontSize: fontSM,
    color: textSecondary,
  );

  static TextStyle get labelBold => GoogleFonts.dmSans(
    fontSize: fontSM,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  // ----------------------------------------------------------
  // MAIN THEME DATA
  // GoogleFonts.dmSansTextTheme() applies DM Sans as the
  // default font for ALL text in the app automatically.
  // ----------------------------------------------------------
  static ThemeData get lightTheme {
    // Start with the base text theme from DM Sans
    final baseTextTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: accentOrange,
        surface: surface,
        background: surface,
      ),

      // Apply DM Sans to all text in the app
      textTheme: baseTextTheme,

      scaffoldBackgroundColor: surface,

      // AppBar styling
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: fontXXL,
          fontWeight: FontWeight.w700,
          color: primaryRed,
        ),
      ),

      // Elevated button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: fontMD,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input field styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: textHint,
          fontSize: fontMD,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceSM + spaceXS,
        ),
      ),
    );
  }
}
