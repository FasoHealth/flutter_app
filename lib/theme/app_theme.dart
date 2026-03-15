import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // --- PALETTE FLASHALERTE (Navy Blue + Orange + Cream) ---
  // Brand colors from React frontend
  static const Color brandOrange = Color(0xFFE8541A);
  static const Color brandOrangeLight = Color(0xFFF4763B);
  static const Color brandOrangePale = Color(0x1EE8541A);
  static const Color brandNavy = Color(0xFF1A2035);
  static const Color brandNavyMid = Color(0xFF243051);
  static const Color brandNavyLight = Color(0xFF2E3D6A);
  static const Color brandCream = Color(0xFFF8F4EE);

  // Semantic colors
  static const Color bgPrimary = Color(0xFFF8F4EE);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgSidebar = Color(0xFF1A2035);
  static const Color textPrimary = Color(0xFF1A2035);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textMuted = Color(0xFF9BA3B4);
  static const Color border = Color(0xFFE8E3DB);

  // Status colors
  static const Color green = Color(0xFF22C55E);
  static const Color greenBg = Color(0x1E22C55E);
  static const Color yellow = Color(0xFFEAB308);
  static const Color yellowBg = Color(0x1EEAB308);
  static const Color red = Color(0xFFEF4444);
  static const Color redBg = Color(0x1EEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueBg = Color(0x1E3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBg = Color(0x1E8B5CF6);

  // Category colors
  static const Color catTheft = Color(0xFF8B5CF6);
  static const Color catAssault = Color(0xFFEF4444);
  static const Color catVandalism = Color(0xFFF59E0B);
  static const Color catSuspicious = Color(0xFF6366F1);
  static const Color catFire = Color(0xFFE8541A);
  static const Color catKidnapping = Color(0xFFF97316);
  static const Color catOther = Color(0xFF6B7280);

  // Legacy names for compatibility
  static const Color accentPurple = brandOrange;
  static const Color accentNeon = brandOrangeLight;
  static const Color dangerRed = red;
  static const Color warningOrange = brandOrange;
  static const Color successGreen = green;
  static const Color primaryBlue = brandNavy;
  static const Color primaryDark = brandNavyMid;
  static const Color textDim = textMuted;

  static const String _keyDarkMode = 'dark_mode';

  static Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // --- LIGHT THEME (FLASHALERTE DESIGN) ---
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgPrimary,
    primaryColor: brandNavy,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: brandNavy,
      secondary: brandOrange,
      surface: bgSecondary,
      error: red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: brandNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: bgSecondary,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brandOrange,
        side: const BorderSide(color: brandOrange),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandOrange,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      hintStyle: GoogleFonts.inter(color: textMuted),
      labelStyle: GoogleFonts.inter(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brandOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelMedium: GoogleFonts.inter(
        color: textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // --- DARK THEME (FLASHALERTE DESIGN) ---
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111827),
    primaryColor: brandNavyLight,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: brandNavyLight,
      secondary: brandOrange,
      surface: Color(0xFF1F2937),
      error: red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF9FAFB),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F2937),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brandOrange,
        side: const BorderSide(color: brandOrange),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 1.0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandOrange,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2937),
      hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
      labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brandOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.inter(
        color: const Color(0xFFF9FAFB),
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        color: const Color(0xFFF9FAFB),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.inter(
        color: const Color(0xFFF9FAFB),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: const Color(0xFFF9FAFB),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: const Color(0xFFE5E7EB),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: const Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelMedium: GoogleFonts.inter(
        color: const Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

