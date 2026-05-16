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

  void _exportData(BuildContext context) {
    final data = context.read<AccountManager>().exportData();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VaporwaveColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: VaporwaveColors.neonPink, width: 2),
        ),
        title: Text(
          'DADOS EXPORTADOS',
          style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copie seus dados abaixo para backup:',
              style: GoogleFonts.chakraPetch(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 150,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: VaporwaveColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: VaporwaveColors.neonPurple),
              ),
              child: SingleChildScrollView(
                child: Text(
                  data,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonCyan)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados copiados para a área de transferência!', style: TextStyle(color: Colors.white)),
                  backgroundColor: VaporwaveColors.neonGreen,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('COPIAR'),
          ),
        ],
      ),
    );
  }

  // --- NOVA FUNÇÃO DE RESTAURAÇÃO DE BACKUP ---
  void _importData(BuildContext context) {
    final data = _importController.text.trim();
    if (data.isEmpty) return;

    final success = context.read<AccountManager>().importData(data);
    
    if (success) {
      _importController.clear();
      FocusScope.of(context).unfocus(); // Esconde o teclado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restaurado com sucesso no Cyber-Espaço!', style: TextStyle(color: Colors.white)),
          backgroundColor: VaporwaveColors.neonGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Formato de dados inválido ou corrompido.', style: TextStyle(color: Colors.white)),
          backgroundColor: VaporwaveColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EXTRA / SETUP',
          style: GoogleFonts.orbitron(
            color: VaporwaveColors.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView( // Mudado para Scroll para caber o campo de texto
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.settings_system_daydream,
              size: 80,
              color: VaporwaveColors.neonPink,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // SESSÃO DE EXPORTAÇÃO
            Text(
              'SISTEMA DE BACKUP',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: VaporwaveColors.neonCyan,
                shadows: [const Shadow(color: VaporwaveColors.neonCyan, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Exporte suas contas para um formato seguro e guarde-as no cofre cibernético.',
              textAlign: TextAlign.center,
              style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                boxShadow: neonGlowPink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _exportData(context),
                icon: const Icon(Icons.download),
                label: Text(
                  'EXPORTAR DADOS',
                  style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            const Divider(color: VaporwaveColors.neonPurple, thickness: 2),
            const SizedBox(height: AppSpacing.xxl),

            // --- NOVA SESSÃO DE IMPORTAÇÃO AQUI ---
            Text(
              'RESTAURAR SISTEMA',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: VaporwaveColors.neonYellow,
                shadows: [const Shadow(color: VaporwaveColors.neonYellow, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cole o código de backup gerado anteriormente para recuperar suas contas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            TextField(
              controller: _importController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Cole o texto JSON aqui...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: VaporwaveColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: VaporwaveColors.neonYellow),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: VaporwaveColors.neonPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: VaporwaveColors.neonYellow),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _importData(context),
              icon: const Icon(Icons.upload, color: VaporwaveColors.surfaceVariant),
              label: Text(
                'IMPORTAR DADOS',
                style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: VaporwaveColors.surfaceVariant),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: VaporwaveColors.neonYellow,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
