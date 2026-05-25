import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_manager.dart';
import 'theme.dart';

// ==========================================================
// TELA PRINCIPAL (MENU DE BOTÕES)
// ==========================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color neonColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: VaporwaveColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: neonColor, width: 2),
            boxShadow: [
              BoxShadow(color: neonColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: neonColor, size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: neonColor.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SETUP', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            _buildMenuButton(
              context,
              'TEMAS',
              Icons.palette,
              VaporwaveColors.neonPink,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemesSubPage())),
            ),
            _buildMenuButton(
              context,
              'BACKUP',
              Icons.security,
              VaporwaveColors.neonCyan,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSubPage())),
            ),
            _buildMenuButton(
              context,
              'DEV',
              Icons.terminal,
              VaporwaveColors.neonYellow,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevSubPage())),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// SUB-PÁGINA: TEMAS
// ==========================================================
class ThemesSubPage extends StatelessWidget {
  const ThemesSubPage({super.key});

  Widget _buildThemeButton(BuildContext context, String title, String themeKey, Color primary, Color secondary, {bool isLocked = false}) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.currentTheme == themeKey;
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;

    return InkWell(
      onTap: isLocked ? null : () => themeProvider.changeTheme(themeKey),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: VaporwaveColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isSelected ? primary : Colors.transparent, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: primary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)] : [],
        ),
        child: Row(
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Container(width: 20, height: 20, decoration: BoxDecoration(color: secondary, shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: GoogleFonts.orbitron(
                  color: isSelected ? (isLight ? Colors.black : Colors.white) : (isLight ? Colors.black54 : Colors.white70), 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                )
              )
            ),
            if (isSelected) Icon(Icons.check_circle, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumThemes(BuildContext context, bool isPremium) {
    Widget themesList = Column(
      children: [
        _buildThemeButton(context, 'Outrun Laranja', 'outrun', VaporwaveColors.neonRed, VaporwaveColors.neonPurple, isLocked: !isPremium),
        _buildThemeButton(context, 'AQUA', 'aqua', VaporwaveColors.aquaPrimary, VaporwaveColors.aquaSecondary, isLocked: !isPremium),
        _buildThemeButton(context, 'MATRIX', 'matrix', VaporwaveColors.matrixPrimary, VaporwaveColors.matrixSecondary, isLocked: !isPremium),
        _buildThemeButton(context, 'DEEP BLUE', 'deepblue', VaporwaveColors.deepBluePrimary, VaporwaveColors.deepBlueSecondary, isLocked: !isPremium),
        
        // Novos Temas com Cores Atualizadas!
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'Sakura Aesthetic', 'sakura', const Color(0xFFFFB7C5), const Color(0xFFFF8DA1), isLocked: !isPremium),
        _buildThemeButton(context, 'Tech Noir (B&W)', 'noir', Colors.white, const Color(0xFF888888), isLocked: !isPremium),
        _buildThemeButton(context, 'Grape Fusion', 'grape', const Color(0xFFD896FF), const Color(0xFF9D4EDD), isLocked: !isPremium),
      ],
    );

    if (isPremium) return themesList;

    return Stack(
      children: [
        themesList,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: VaporwaveColors.neonYellow, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'PREMIUM NECESSÁRIO',
                        style: GoogleFonts.orbitron(
                          color: VaporwaveColors.neonYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AccountManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text('TEMAS', style: GoogleFonts.orbitron(color: VaporwaveColors.neonPink, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VaporwaveColors.neonPink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Single
