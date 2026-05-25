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
  static Brightness currentBrightness = Brightness.dark; // NOVO: Controle de Claro/Escuro
  
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

  static void loadVaporwave() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF0D0221);
    surface = const Color(0xFF1B0330);
    surfaceVariant = const Color(0xFF2E094F);
    neonPink = const Color(0xFFFF00FF);
    neonCyan = const Color(0xFF00FFFF);
    neonPurple = const Color(0xFF9D00FF);
    neonGreen = const Color(0xFF39FF14);
    neonRed = const Color(0xFFFF073A);
  }

  static void loadCyberpunk() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF090909);
    surface = const Color(0xFF1C1C1C);
    surfaceVariant = const Color(0xFF2D2D2D);
    neonPink = const Color(0xFF00FFFF);
    neonCyan = const Color(0xFFFCEE09);
    neonPurple = const Color(0xFFFF003C);
    neonGreen = const Color(0xFF39FF14);
    neonRed = const Color(0xFFFF073A);
  }

  static void loadOutrun() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF10002B);
    surface = const Color(0xFF240046);
    surfaceVariant = const Color(0xFF3C096C);
    neonPink = const Color(0xFFFF6600);
    neonCyan = const Color(0xFFE0AAFF);
    neonPurple = const Color(0xFF5A189A);
    neonGreen = const Color(0xFF39FF14);
    neonRed = const Color(0xFFFF073A);
  }

  static void loadAqua() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF001F3F);
    surface = const Color(0xFF003366);
    surfaceVariant = const Color(0xFF004A99);
    neonPink = const Color(0xFF00D2FF);
    neonCyan = const Color(0xFF7FFFD4);
    neonPurple = const Color(0xFF00BFFF);
  }

  static void loadMatrix() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF000000);
    surface = const Color(0xFF0D140D);
    surfaceVariant = const Color(0xFF1B261B);
    neonPink = const Color(0xFF00FF41);
    neonCyan = const Color(0xFF39FF14);
    neonPurple = const Color(0xFF008F11);
  }

  static void loadDeepBlue() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF000510);
    surface = const Color(0xFF001020);
    surfaceVariant = const Color(0xFF002040);
    neonPink = const Color(0xFF0055FF);
    neonCyan = const Color(0xFF00C3FF);
    neonPurple = const Color(0xFF001144);
  }

  // --- NOVOS TEMAS AQUI ---
  static void loadSakura() {
    currentBrightness = Brightness.light;
    background = const Color(0xFFFDFDFD);
    surface = const Color(0xFFFFF0F2);
    surfaceVariant = const Color(0xFFFFE4E8);
    neonPink = const Color(0xFFFFB7C5);
    neonCyan = const Color(0xFF74C337);
    neonPurple = const Color(0xFF5D1F33);
  }

  static void loadNoir() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF000000);
    surface = const Color(0xFF111111);
    surfaceVariant = const Color(0xFF222222);
    neonPink = Colors.white;
    neonCyan = const Color(0xFF888888);
    neonPurple = Colors.white70;
  }

  static void loadGrape() {
    currentBrightness = Brightness.dark;
    background = const Color(0xFF1A0B2E);
    surface = const Color(0xFF3B1E6D);
    surfaceVariant = const Color(0xFF4C2A85);
    neonPink = const Color(0xFFE0B0FF);
    neonCyan = const Color(0xFFF0F0D0);
    neonPurple = const Color(0xFFFFAB91);
  }
}

List<BoxShadow> get neonGlowPink => [
      BoxShadow(color: VaporwaveColors.neonPink.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2),
      BoxShadow(color: VaporwaveColors.neonPink.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4),
    ];

List<BoxShadow> get neonGlowCyan => [
      BoxShadow(color: VaporwaveColors.neonCyan.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2),
      BoxShadow(color: VaporwaveColors.neonCyan.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4),
    ];

class ThemeProvider with ChangeNotifier {
  String _currentTheme = 'vaporwave';
  String get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('app_theme') ?? 'vaporwave';
    _applyTheme(_currentTheme);
    notifyListeners();
  }

  Future<void> changeTheme(String themeName) async {
    _currentTheme = themeName;
    _applyTheme(themeName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeName);
    notifyListeners();
  }

  void _applyTheme(String theme) {
    switch (theme) {
      case 'cyberpunk': VaporwaveColors.loadCyberpunk(); break;
      case 'outrun': VaporwaveColors.loadOutrun(); break;
      case 'aqua': VaporwaveColors.loadAqua(); break;
      case 'matrix': VaporwaveColors.loadMatrix(); break;
      case 'deepblue': VaporwaveColors.loadDeepBlue(); break;
      case 'sakura': VaporwaveColors.loadSakura(); break;
      case 'noir': VaporwaveColors.loadNoir(); break;
      case 'grape': VaporwaveColors.loadGrape(); break;
      default: VaporwaveColors.loadVaporwave(); break;
    }
  }

  ThemeData getThemeData() {
    Color primary = VaporwaveColors.neonPink;
    Color secondary = VaporwaveColors.neonCyan;
    Color background = VaporwaveColors.background;
    Color surface = VaporwaveColors.surface;
    Color surfaceVariant = VaporwaveColors.surfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: VaporwaveColors.currentBrightness, // Puxa do tema (Light/Dark)
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: VaporwaveColors.currentBrightness,
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
