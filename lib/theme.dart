import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // As cores agora não são "const", elas podem mudar!
  static Color background = const Color(0xFF0D0221);
  static Color surface = const Color(0xFF1B0330);
  static Color surfaceVariant = const Color(0xFF2E094F);

  static Color neonPink = const Color(0xFFFF00FF);
  static Color neonCyan = const Color(0xFF00FFFF);
  static Color neonPurple = const Color(0xFF9D00FF);
  static Color neonBlue = const Color(0xFF0033FF);
  static Color neonYellow = const Color(0xFFFFCC00);

  static Color neonGreen = const Color(0xFF39FF14);
  static Color neonRed = const Color(0xFFFF003C);

  static void loadVaporwave() {
    background = const Color(0xFF0D0221);
    surface = const Color(0xFF1B0330);
    surfaceVariant = const Color(0xFF2E094F);
    neonPink = const Color(0xFFFF00FF);
    neonCyan = const Color(0xFF00FFFF);
    neonPurple = const Color(0xFF9D00FF);
  }

  static void loadCyberpunk() {
    background = const Color(0xFF090909);
    surface = const Color(0xFF1C1C1C);
    surfaceVariant = const Color(0xFF2D2D2D);
    neonPink = const Color(0xFF00FFFF); // Troca Rosa por Ciano
    neonCyan = const Color(0xFFFCEE09); // Troca Ciano por Amarelo
    neonPurple = const Color(0xFFFF003C); // Acentos em Vermelho
  }

  static void loadOutrun() {
    background = const Color(0xFF10002B);
    surface = const Color(0xFF240046);
    surfaceVariant = const Color(0xFF3C096C);
    neonPink = const Color(0xFFFF6600); // Laranja Neon
    neonCyan = const Color(0xFFE0AAFF); // Roxo suave
    neonPurple = const Color(0xFF5A189A); // Roxo profundo
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

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VaporwaveColors.background,
      colorScheme: ColorScheme.dark(
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
          shadows: [Shadow(color: VaporwaveColors.neonCyan, blurRadius: 8)],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VaporwaveColors.surface,
        labelStyle: TextStyle(color: VaporwaveColors.neonCyan),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: VaporwaveColors.neonPurple, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: VaporwaveColors.neonPink, width: 2),
        ),
        prefixIconColor: VaporwaveColors.neonCyan,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VaporwaveColors.surface,
        selectedItemColor: VaporwaveColors.neonPink,
        unselectedItemColor: VaporwaveColors.neonCyan,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );

// O GERENCIADOR DE TEMAS
class ThemeProvider extends ChangeNotifier {
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
    if (theme == 'cyberpunk') {
      VaporwaveColors.loadCyberpunk();
    } else if (theme == 'outrun') {
      VaporwaveColors.loadOutrun();
    } else {
      VaporwaveColors.loadVaporwave();
    }
  }
}
