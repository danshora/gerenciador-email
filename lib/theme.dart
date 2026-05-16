import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class VaporwaveColors {
  // Deep Backgrounds
  static const background = Color(0xFF0D0221); // Deep void
  static const surface = Color(0xFF1B0330); // Dark purple
  static const surfaceVariant = Color(0xFF2E094F);

  // Neon Accents
  static const neonPink = Color(0xFFFF00FF); // Magenta
  static const neonCyan = Color(0xFF00FFFF); // Cyan
  static const neonPurple = Color(0xFF9D00FF);
  static const neonBlue = Color(0xFF0033FF);
  static const neonYellow = Color(0xFFFFCC00);

  // Status Colors
  static const neonGreen = Color(0xFF39FF14);
  static const neonRed = Color(0xFFFF003C);
}

// Glowing effect constants
List<BoxShadow> get neonGlowPink => [
      BoxShadow(color: VaporwaveColors.neonPink.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2),
      BoxShadow(color: VaporwaveColors.neonPink.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4),
    ];

List<BoxShadow> get neonGlowCyan => [
      BoxShadow(color: VaporwaveColors.neonCyan.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2),
      BoxShadow(color: VaporwaveColors.neonCyan.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4),
    ];

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VaporwaveColors.background,
      colorScheme: const ColorScheme.dark(
        primary: VaporwaveColors.neonPink,
        onPrimary: Colors.white,
        secondary: VaporwaveColors.neonCyan,
        onSecondary: Colors.black,
        tertiary: VaporwaveColors.neonYellow,
        surface: VaporwaveColors.surface,
        onSurface: Colors.white,
        error: VaporwaveColors.neonRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VaporwaveColors.surface.withValues(alpha: 0.8),
        foregroundColor: VaporwaveColors.neonCyan,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: VaporwaveColors.neonCyan,
          shadows: [
            Shadow(color: VaporwaveColors.neonCyan, blurRadius: 8),
          ],
        ),
      ),
      cardTheme: CardThemeData(
        color: VaporwaveColors.surfaceVariant,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: VaporwaveColors.neonPurple, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VaporwaveColors.surface,
        labelStyle: const TextStyle(color: VaporwaveColors.neonCyan),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: VaporwaveColors.neonPurple, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: VaporwaveColors.neonPink, width: 2),
        ),
        prefixIconColor: VaporwaveColors.neonCyan,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VaporwaveColors.background,
          foregroundColor: VaporwaveColors.neonPink,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: VaporwaveColors.neonPink, width: 2),
          ),
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16),
        ).copyWith(
          elevation: WidgetStateProperty.all(10),
          shadowColor: WidgetStateProperty.all(VaporwaveColors.neonPink),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan),
        titleLarge: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w600, color: VaporwaveColors.neonPink),
        bodyLarge: GoogleFonts.chakraPetch(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.chakraPetch(fontSize: 14, color: Colors.white70),
        labelLarge: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VaporwaveColors.surface,
        selectedItemColor: VaporwaveColors.neonPink,
        unselectedItemColor: VaporwaveColors.neonCyan,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );

ThemeData get lightTheme => darkTheme; // Force vaporwave dark mode style
