import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';
import 'account.dart';
import 'account_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _hasExpiration = true; // Toggle para conta permanente
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --- AUTO-LIMPEZA DO CLIPBOARD ---
  void _copyToClipboardSecure(String text, String fieldName, {bool isSensitive = false}) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    
    String msg = '$fieldName copiado!';
    if (isSensitive) {
      msg += ' (Sumiço em 30s ⏱️)';
      Timer(const Duration(seconds: 30), () async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData != null && clipboardData.text == text) {
          Clipboard.setData(const ClipboardData(text: '')); // Limpa o clipboard
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonPurple),
    );
  }

  // --- FORJA DE E-MAIL (DIA 2) ---
  void _showEmailForgeDialog() {
    final prefixController = TextEditingController();
    String selectedDomain = '@gmail.com';
    final customDomainController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            backgroundColor: VaporwaveColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonCyan)),
            title: Text('FORJA DE LOGIN', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: prefixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Prefixo (Ex: player1)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true, fillColor: VaporwaveColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButton<String>(
                    value: selectedDomain,
                    dropdownColor: VaporwaveColors.surfaceVariant,
                    isExpanded: true,
                    style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonYellow, fontSize: 14),
                    items: ['@gmail.com', '@hotmail.com', '@outlook.com', 'Customizado'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setStateBuilder(() => selectedDomain = val!),
                  ),
                  if (selectedDomain == 'Customizado') ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: customDomainController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '@seuservidor.com',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true, fillColor: VaporwaveColors.surface,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonCyan),
                onPressed: () {
                  final prefix = prefixController.text.trim().isEmpty ? 'neon_user${Random().nextInt(999)}' : prefixController.text.trim();
                  final domain = selectedDomain == 'Customizado' ? customDomainController.text.trim() : selectedDomain;
                  final finalDomain = domain.startsWith('@') ? domain : '@$domain';
                  _emailController.text = '$prefix$finalDomain';
                  Navigator.pop(context);
                },
                child: Text('APLICAR', style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- FORJA DE SENHA (DIA 1) ---
  void _showPasswordForgeDialog() {
    double length = 16;
    bool useUpper = true;
    bool useLower = true;
    bool useNum = true;
    bool useSym = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            backgroundColor: VaporwaveColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonYellow)),
            title: Text('FORJA DE SENHA', style: GoogleFonts.orbitron(color: VaporwaveColors.neonYellow)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamanho: ${length.toInt()} caracteres', style: GoogleFonts.chakraPetch(color: Colors.white)),
                  Slider(
                    value: length, min: 8, max: 64, divisions: 56,
                    activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => length = val),
                  ),
                  CheckboxListTile(
                    title: const Text('Maiúsculas (A-Z)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: useUpper, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => useUpper = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Minúsculas (a-z)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: useLower, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => useLower = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Números (0-9)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: useNum, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => useNum = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Símbolos (!@#\$%)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: useSym, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => useSym = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonYellow),
                onPressed: () {
                  if (!useUpper && !useLower && !useNum && !useSym) return; // Precisa de pelo menos 1
                  String chars = '';
                  if (useUpper) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                  if (useLower) chars += 'abcdefghijklmnopqrstuvwxyz';
                  if (useNum) chars += '0123456789';
                  if (useSym) chars += '!@#\$%^&*()-_=+';
                  
                  final rnd = Random();
                  final res = String.fromCharCodes(Iterable.generate(length.toInt(), (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
                  _passwordController.text = res;
                  Navigator.pop(context);
                },
                child: Text('GERAR', style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _saveAccount() {
    if (_titleController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Preencha os campos obrigatórios', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonRed),
      );
      return;
    }

    final account = Account(
      title: _titleController.text,
      email: _emailController.text,
      password: _passwordController.text,
      hasExpiration: _hasExpiration, // Adiciona configuração vitalícia
      daysLeft: 30,
      expiresAt: _hasExpiration ? DateTime.now().add(const Duration(days: 30)) : null,
    );

    context.read<AccountManager>().addAccount(account);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Dados forjados com sucesso!', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonGreen),
    );

    _titleController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _hasExpiration = true); // Reseta toggle
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hintText, required IconData icon, bool isPassword = false, VoidCallback? onSettings, VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(boxShadow: neonGlowCyan, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: TextField(
                    controller: controller, obscureText: isPassword, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(prefixIcon: Icon(icon, color: VaporwaveColors.neonCyan), hintText: hintText, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none), filled: true, fillColor: VaporwaveColors.surface),
                  ),
                ),
              ),
              if (onSettings != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(onPressed: onSettings, icon: Icon(Icons.settings_suggest, color: VaporwaveColors.neonYellow), tooltip: 'Configurar Gerador'),
              ],
              if (onCopy != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(onPressed: onCopy, icon: Icon(Icons.copy, color: VaporwaveColors.neonPink), tooltip: 'Copiar'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Text('CYBER-FORJA', style: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.bold, color: VaporwaveColors.neonPink, shadows: [Shadow(color: VaporwaveColors.neonPink.withValues(alpha: 0.5 + (_glowController.value * 0.5)), blurRadius: 10 + (_glowController.value * 15))])),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Forje novas credenciais ou gere acessos\ncom parâmetros avançados.', textAlign: TextAlign.center, style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 13, height: 1.4)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              _buildTextField(controller: _titleController, label: 'Identificador do Serviço', hintText: 'Ex: Steam, Banco...', icon: Icons.title),
              _buildTextField(controller: _emailController, label: 'Usuário / E-mail', hintText: 'Digite ou gere um login', icon: Icons.person, onSettings: _showEmailForgeDialog, onCopy: () => _copyToClipboardSecure(_emailController.text, 'Login')),
              _buildTextField(controller: _passwordController, label: 'Senha de Acesso', hintText: 'Digite ou gere uma senha', icon: Icons.lock, isPassword: true, onSettings: _showPasswordForgeDialog, onCopy: () => _copyToClipboardSecure(_passwordController.text, 'Senha', isSensitive: true)),
              
              // --- TOGGLE VITALÍCIO ---
              SwitchListTile(
                title: Text('Ativar Cronômetro de Validade?', style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonCyan)),
                subtitle: Text(_hasExpiration ? 'A conta vencerá em 30 dias (pode alterar depois).' : 'Conta permanente. Nunca irá expirar.', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                value: _hasExpiration,
                activeColor: VaporwaveColors.neonCyan,
                onChanged: (val) => setState(() => _hasExpiration = val),
              ),

              const SizedBox(height: AppSpacing.xl),
              
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(boxShadow: neonGlowPink, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.surfaceVariant, padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), side: BorderSide(color: VaporwaveColors.neonPink.withValues(alpha: 0.8 + (_glowController.value * 0.2)), width: 2)),
                      child: Text('FORJAR ACESSO', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: VaporwaveColors.neonPink, letterSpacing: 2)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
