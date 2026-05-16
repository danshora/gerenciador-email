import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports corrigidos para a raiz
import 'account_manager.dart';
import 'theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            child: Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonCyan)),
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
      body: Padding(
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
            Text(
              'SISTEMA DE BACKUP',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: VaporwaveColors.neonCyan,
                shadows: [Shadow(color: VaporwaveColors.neonCyan, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Exporte suas contas para um formato seguro e guarde-as no cofre cibernético.',
              textAlign: TextAlign.center,
              style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xxl),
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
          ],
        ),
      ),
    );
  }
}
