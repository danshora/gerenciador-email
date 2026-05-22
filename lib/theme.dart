import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
}

class VaporwaveColors {
  static Color background = const Color(0xFF0D0221);
  static Color surface = const Color(0xFF1B0330);
  static Color surfaceVariant = const Color(0xFF2E094F);
  static Color neonPink = const Color(0xFFFF00FF);
  static Color neonCyan = const Color(0xFF00FFFF);
  static Color neonPurple = const Color(0xFF9D00FF);
  static Color neonYellow = const Color(0xFFFFCC00);
  static Color neonGreen = const Color(0xFF39FF14);
  static Color neonRed = const Color(0xFFFF073A);

  static const Color aquaPrimary = Color(0xFF00D2FF);
  static const Color aquaSecondary = Color(0xFF3A7BD5);
  static const Color matrixPrimary = Color(0xFF00FF41);
  static const Color matrixSecondary = Color(0xFF003B00);
  static const Color deepBluePrimary = Color(0xFF0055FF);
  static const Color deepBlueSecondary = Color(0xFF001144);
}

class ThemeProvider with ChangeNotifier {
  String _currentTheme = 'vaporwave';
  String get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('app_theme') ?? 'vaporwave';
    notifyListeners();
  }

  Future<void> changeTheme(String themeName) async {
    _currentTheme = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeName);
    notifyListeners();
  }

  // MÉTODO DINÂMICO QUE O MAIN.DART VAI CHAMAR
  ThemeData getThemeData() {
    Color primary;
    Color secondary;
    Color background;
    Color surface;
    Color surfaceVariant;

    switch (_currentTheme) {
      case 'cyberpunk':
        primary = VaporwaveColors.neonCyan;
        secondary = VaporwaveColors.neonYellow;
        background = const Color(0xFF090909);
        surface = const Color(0xFF1C1C1C);
        surfaceVariant = const Color(0xFF2D2D2D);
        break;
      case 'outrun':
        primary = VaporwaveColors.neonRed;
        secondary = VaporwaveColors.neonPurple;
        background = const Color(0xFF10002B);
        surface = const Color(0xFF240046);
        surfaceVariant = const Color(0xFF3C096C);
        break;
      case 'aqua':
        primary = VaporwaveColors.aquaPrimary;
        secondary = VaporwaveColors.aquaSecondary;
        background = const Color(0xFF001F3F);
        surface = const Color(0xFF003366);
        surfaceVariant = const Color(0xFF004A99);
        break;
      case 'matrix':
        primary = VaporwaveColors.matrixPrimary;
        secondary = VaporwaveColors.matrixSecondary;
        background = const Color(0xFF000000);
        surface = const Color(0xFF0D140D);
        surfaceVariant = const Color(0xFF1B261B);
        break;
      case 'deepblue':
        primary = VaporwaveColors.deepBluePrimary;
        secondary = VaporwaveColors.deepBlueSecondary;
        background = const Color(0xFF000510);
        surface = const Color(0xFF001020);
        surfaceVariant = const Color(0xFF002040);
        break;
      default: // vaporwave
        primary = VaporwaveColors.neonPink;
        secondary = VaporwaveColors.neonCyan;
        background = const Color(0xFF0D0221);
        surface = const Color(0xFF1B0330);
        surfaceVariant = const Color(0xFF2E094F);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        error: VaporwaveColors.neonRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: 0.8),
        foregroundColor: primary,
        titleTextStyle: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: secondary.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: primary, width: 2)),
      ),
    );
  }
}
