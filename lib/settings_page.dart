import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_manager.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _showPasswordDialog({
    required String title,
    required String buttonText,
    required Function(String) onSubmit,
  }) {
    final pwController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VaporwaveColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: VaporwaveColors.neonYellow, width: 2),
        ),
        title: Text(title, style: GoogleFonts.orbitron(color: VaporwaveColors.neonYellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Digite uma senha para trancar/destrancar este backup:', style: GoogleFonts.chakraPetch(color: Colors.white70)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: pwController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Sua senha secreta...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: VaporwaveColors.surface,
                prefixIcon: Icon(Icons.key, color: VaporwaveColors.neonYellow),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: VaporwaveColors.neonPurple)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide(color: VaporwaveColors.neonYellow)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonYellow),
            onPressed: () {
              final pw = pwController.text.trim();
              if (pw.isNotEmpty) {
                Navigator.pop(context);
                onSubmit(pw);
              }
            },
            child: Text(buttonText, style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    _showPasswordDialog(
      title: 'SENHA DE EXPORTAÇÃO',
      buttonText: 'GERAR BACKUP',
      onSubmit: (password) {
        final data = context.read<AccountManager>().exportData(password);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: VaporwaveColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonPink, width: 2)),
            title: Text('COFRE TRANCADO', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Este código só pode ser aberto com a senha que você acabou de criar:', style: GoogleFonts.chakraPetch(color: Colors.white)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(color: VaporwaveColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: VaporwaveColors.neonPurple)),
                  child: SingleChildScrollView(child: Text(data, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonCyan))),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: data));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Dados copiados!'), backgroundColor: VaporwaveColors.neonGreen));
                },
                icon: const Icon(Icons.copy), label: const Text('COPIAR'),
              ),
            ],
          ),
        );
      }
    );
  }

  void _importData(BuildContext context) {
    final data = _importController.text.trim();
    if (data.isEmpty) return;
    _showPasswordDialog(
      title: 'SENHA DE RESTAURAÇÃO',
      buttonText: 'DESTRANCAR',
      onSubmit: (password) {
        final success = context.read<AccountManager>().importData(data, password);
        if (success) {
          _importController.clear();
          FocusScope.of(context).unfocus();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Backup restaurado!'), backgroundColor: VaporwaveColors.neonGreen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Senha incorreta ou erro.'), backgroundColor: VaporwaveColors.neonRed));
        }
      }
    );
  }

  Widget _buildThemeButton(BuildContext context, String title, String themeKey, Color primary, Color secondary, {bool isLocked = false}) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.currentTheme == themeKey;
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;

    return InkWell(
      onTap: isLocked ? null : () => themeProvider.changeTheme(themeKey),
      child: Container(
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
            Expanded(child: Text(title, style: GoogleFonts.orbitron(color: isSelected ? (isLight ? Colors.black : Colors.white) : (isLight ? Colors.black54 : Colors.white70), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
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
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'AQUA', 'aqua', VaporwaveColors.aquaPrimary, VaporwaveColors.aquaSecondary, isLocked: !isPremium),
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'MATRIX', 'matrix', VaporwaveColors.matrixPrimary, VaporwaveColors.matrixSecondary, isLocked: !isPremium),
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'DEEP BLUE', 'deepblue', VaporwaveColors.deepBluePrimary, VaporwaveColors.deepBlueSecondary, isLocked: !isPremium),
        
        // Novos Temas
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'Sakura Aesthetic', 'sakura', const Color(0xFFFFB7C5), const Color(0xFF74C337), isLocked: !isPremium),
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'Tech Noir (B&W)', 'noir', Colors.white, const Color(0xFF888888), isLocked: !isPremium),
        const SizedBox(height: AppSpacing.sm),
        _buildThemeButton(context, 'Grape Fusion', 'grape', const Color(0xFFE0B0FF), const Color(0xFFF0F0D0), isLocked: !isPremium),
      ],
    );

    if (isPremium) {
      return themesList;
    }

    // Camada de Blur para usuários Free
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
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('SETUP', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: VaporwaveColors.neonPink,
            labelColor: VaporwaveColors.neonPink,
            unselectedLabelColor: isLight ? Colors.black54 : Colors.white54,
            labelStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.palette), text: 'VISUAL'),
              Tab(icon: Icon(Icons.security), text: 'COFRE'),
              Tab(icon: Icon(Icons.terminal), text: 'SISTEMA'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- ABA 1: VISUAL (TEMAS) ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('INTERFACE E CORES', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan)),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Temas Free
                  _buildThemeButton(context, 'Vaporwave Clássico', 'vaporwave', VaporwaveColors.neonPink, VaporwaveColors.neonCyan),
                  const SizedBox(height: AppSpacing.sm),
                  _buildThemeButton(context, 'Cyberpunk Amarelo', 'cyberpunk', VaporwaveColors.neonCyan, VaporwaveColors.neonYellow),
                  const SizedBox(height: AppSpacing.xl),

                  // Temas Premium (Bloqueados com Blur)
                  Text('TEMAS PREMIUM', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: VaporwaveColors.neonYellow)),
                  const SizedBox(height: AppSpacing.md),
                  _buildPremiumThemes(context, manager.isPremium),
                ],
              ),
            ),

            // --- ABA 2: COFRE (BACKUPS) ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SISTEMA DE BACKUP', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan)),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(boxShadow: neonGlowPink, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: ElevatedButton.icon(
                      onPressed: () => _exportData(context),
                      icon: const Icon(Icons.lock_outline),
                      label: Text('EXPORTAR COM SENHA', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _importController,
                    maxLines: 4,
                    style: TextStyle(color: textColor, fontSize: 12),
                    decoration: InputDecoration(hintText: 'Cole o código encriptado aqui...', filled: true, fillColor: VaporwaveColors.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () => _importData(context),
                    icon: Icon(Icons.key, color: VaporwaveColors.surfaceVariant),
                    label: Text('DESTRANCAR E IMPORTAR', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: VaporwaveColors.surfaceVariant)),
                    style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonYellow, padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                  ),
                ],
              ),
            ),

            // --- ABA 3: SISTEMA (DEV) ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: VaporwaveColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: VaporwaveColors.neonPurple)),
                    child: SwitchListTile(
                      title: Text('VAPOR PREMIUM', style: GoogleFonts.chakraPetch(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('Libera 10 tags globais e temas.', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 12)),
                      value: manager.isPremium,
                      activeColor: VaporwaveColors.neonYellow,
                      onChanged: (bool value) {
                        manager.togglePremium();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Premium Ativado!' : 'Free Ativado.')));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
