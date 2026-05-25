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
    // CORREÇÃO SAKURA: Se for fundo claro, a cor da letra e do ícone ficam mais escuras
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;
    final activeColor = isLight ? VaporwaveColors.neonPurple : neonColor;
    final textColor = isLight ? VaporwaveColors.neonPurple : Colors.white;

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
            border: Border.all(color: activeColor, width: 2),
            boxShadow: [
              BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: activeColor, size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: textColor, // Agora aplica a cor certa para dar contraste
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: activeColor.withValues(alpha: 0.7), size: 20),
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
                  color: primary, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  shadows: [
                    Shadow(color: primary.withValues(alpha: 0.4), blurRadius: 4), 
                  ]
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('INTERFACE E CORES', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan)),
            const SizedBox(height: AppSpacing.md),
            
            _buildThemeButton(context, 'Vaporwave Clássico', 'vaporwave', VaporwaveColors.neonPink, VaporwaveColors.neonCyan),
            _buildThemeButton(context, 'Cyberpunk Amarelo', 'cyberpunk', VaporwaveColors.neonCyan, VaporwaveColors.neonYellow),
            const SizedBox(height: AppSpacing.xl),

            Text('TEMAS PREMIUM', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: VaporwaveColors.neonYellow)),
            const SizedBox(height: AppSpacing.md),
            _buildPremiumThemes(context, manager.isPremium),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// SUB-PÁGINA: BACKUP
// ==========================================================
class BackupSubPage extends StatefulWidget {
  const BackupSubPage({super.key});

  @override
  State<BackupSubPage> createState() => _BackupSubPageState();
}

class _BackupSubPageState extends State<BackupSubPage> {
  final _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _showPasswordDialog({required String title, required String buttonText, required Function(String) onSubmit}) {
    final pwController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VaporwaveColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md), 
          side: BorderSide(color: VaporwaveColors.neonYellow, width: 2)
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm), 
                  borderSide: BorderSide(color: VaporwaveColors.neonPurple)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm), 
                  borderSide: BorderSide(color: VaporwaveColors.neonYellow)
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink))
          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md), 
              side: BorderSide(color: VaporwaveColors.neonPink, width: 2)
            ),
            title: Text('COFRE TRANCADO', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Este código só pode ser aberto com a senha que você acabou de criar:', style: GoogleFonts.chakraPetch(color: Colors.white)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: VaporwaveColors.surface, 
                    borderRadius: BorderRadius.circular(AppRadius.sm), 
                    border: Border.all(color: VaporwaveColors.neonPurple)
                  ),
                  child: SingleChildScrollView(
                    child: Text(data, style: const TextStyle(color: Colors.white70, fontSize: 12))
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonCyan))
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: data));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Dados copiados!'), backgroundColor: VaporwaveColors.neonGreen)
                  );
                },
                icon: const Icon(Icons.copy), 
                label: const Text('COPIAR'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Backup restaurado!'), backgroundColor: VaporwaveColors.neonGreen)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Senha incorreta ou erro.'), backgroundColor: VaporwaveColors.neonRed)
          );
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('BACKUP', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VaporwaveColors.neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SISTEMA DE BACKUP', 
              textAlign: TextAlign.center, 
              style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: VaporwaveColors.neonCyan)
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                boxShadow: neonGlowPink, 
                borderRadius: BorderRadius.circular(AppRadius.md)
              ),
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
              decoration: InputDecoration(
                hintText: 'Cole o código encriptado aqui...', 
                filled: true, 
                fillColor: VaporwaveColors.surfaceVariant, 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md), 
                  borderSide: BorderSide.none
                )
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => _importData(context),
              icon: Icon(Icons.key, color: VaporwaveColors.surfaceVariant),
              label: Text('DESTRANCAR E IMPORTAR', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: VaporwaveColors.surfaceVariant)),
              style: ElevatedButton.styleFrom(
                backgroundColor: VaporwaveColors.neonYellow, 
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// SUB-PÁGINA: DEV (SISTEMA) - Atualizado para persistência
// ==========================================================
class DevSubPage extends StatelessWidget {
  const DevSubPage({super.key});

  void _showDevKeyDialog(BuildContext context, AccountManager manager) {
    final keyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VaporwaveColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md), 
          side: BorderSide(color: VaporwaveColors.neonRed, width: 2)
        ),
        title: Text('MODO DESENVOLVEDOR', style: GoogleFonts.orbitron(color: VaporwaveColors.neonRed)),
        content: TextField(
          controller: keyController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Digite a chave de acesso...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true, 
            fillColor: VaporwaveColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm), 
              borderSide: BorderSide(color: VaporwaveColors.neonPurple)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm), 
              borderSide: BorderSide(color: VaporwaveColors.neonRed)
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonRed),
            onPressed: () {
              if (keyController.text.trim() == 'heaWSvcTPLccA8SzNeGv5zW3') {
                Navigator.pop(dialogContext);
                manager.unlockDevMode(); // <--- CHAMA A FUNÇÃO PARA SALVAR NA MEMÓRIA!
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Modo Desenvolvedor Ativado!', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonGreen)
                );
              } else {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Acesso Negado: Chave Incorreta!', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonRed)
                );
              }
            },
            child: const Text('AUTENTICAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AccountManager>();
    final isDevUnlocked = manager.isDevUnlocked; // Lê direto da memória!
    
    final isLight = VaporwaveColors.currentBrightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('DEV & SISTEMA', style: GoogleFonts.orbitron(color: VaporwaveColors.neonYellow, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VaporwaveColors.neonYellow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // ============================================
            // CAIXA VERMELHA - Ativar Modo Desenvolvedor
            // ============================================
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: VaporwaveColors.surfaceVariant, 
                borderRadius: BorderRadius.circular(AppRadius.md), 
                border: Border.all(
                  color: isDevUnlocked ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed, 
                  width: 2
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDevUnlocked ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed).withValues(alpha: 0.3), 
                    blurRadius: 8, 
                    spreadRadius: 1
                  )
                ]
              ),
              child: ListTile(
                leading: Icon(
                  isDevUnlocked ? Icons.developer_mode : Icons.lock_outline, 
                  color: isDevUnlocked ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed, 
                  size: 32
                ),
                title: Text(
                  isDevUnlocked ? 'MODO DEV ATIVO' : 'ATIVAR MODO DESENVOLVEDOR', 
                  style: GoogleFonts.orbitron(color: textColor, fontWeight: FontWeight.bold)
                ),
                subtitle: Text('Acesso restrito à engenharia.', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 12)),
                trailing: isDevUnlocked 
                  ? Icon(Icons.check_circle, color: VaporwaveColors.neonGreen) 
                  : Icon(Icons.key, color: VaporwaveColors.neonRed),
                onTap: isDevUnlocked ? null : () => _showDevKeyDialog(context, manager),
              ),
            ),

            // ============================================
            // CAIXAS VERDES - Opções (Aparecem só se ativo)
            // ============================================
            if (isDevUnlocked) ...[
              
              // OPÇÃO 1: Modo Premium
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: VaporwaveColors.surfaceVariant, 
                  borderRadius: BorderRadius.circular(AppRadius.md), 
                  border: Border.all(color: VaporwaveColors.neonGreen, width: 1.5)
                ),
                child: SwitchListTile(
                  title: Text('MODO PREMIUM (SIMULAÇÃO)', style: GoogleFonts.chakraPetch(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text('Libera 10 tags globais e temas premium.', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 12)),
                  value: manager.isPremium,
                  activeColor: VaporwaveColors.neonGreen,
                  secondary: Icon(Icons.workspace_premium, color: VaporwaveColors.neonGreen),
                  onChanged: (bool value) {
                    manager.togglePremium();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? 'Premium Ativado!' : 'Free Ativado.', style: const TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonGreen)
                    );
                  },
                ),
              ),

              // OPÇÃO 2: Reset App (Para Testes)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: VaporwaveColors.surfaceVariant, 
                  borderRadius: BorderRadius.circular(AppRadius.md), 
                  border: Border.all(color: VaporwaveColors.neonGreen, width: 1.5)
                ),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: VaporwaveColors.neonGreen, size: 28),
                  title: Text('RESET APP (FACTORY RESET)', style: GoogleFonts.chakraPetch(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text('Apaga todas as contas, tags e configurações.', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 12)),
                  trailing: Icon(Icons.delete_forever, color: VaporwaveColors.neonGreen),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: VaporwaveColors.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonRed, width: 2)),
                        title: Text('ATENÇÃO: PERIGO', style: GoogleFonts.orbitron(color: VaporwaveColors.neonRed, fontWeight: FontWeight.bold)),
                        content: const Text('Isto apagará TODO o cofre permanentemente. Continuar?', style: TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonCyan))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonRed),
                            onPressed: () {
                              manager.factoryReset(); // <--- O Reset também tranca o DEV novamente
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('App resetado com sucesso!', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonGreen)
                              );
                            },
                            child: const Text('RESETAR TUDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    );
                  },
                ),
              ),

              // OPÇÃO 3: WIP (Work in Progress)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: VaporwaveColors.surfaceVariant, 
                  borderRadius: BorderRadius.circular(AppRadius.md), 
                  border: Border.all(color: VaporwaveColors.neonGreen, width: 1.5)
                ),
                child: ListTile(
                  leading: Icon(Icons.construction, color: VaporwaveColors.neonGreen, size: 28),
                  title: Text('WIP (WORK IN PROGRESS)', style: GoogleFonts.chakraPetch(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text('Módulo em desenvolvimento futuro.', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 12)),
                  trailing: Icon(Icons.science, color: VaporwaveColors.neonGreen),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Em breve...', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonCyan)
                    );
                  },
                ),
              ),

            ]
          ],
        ),
      ),
    );
  }
}
