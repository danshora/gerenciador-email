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
  
  bool _hasExpiration = true; 
  late AnimationController _glowController;

  // --- MEMÓRIA DAS CONFIGURAÇÕES DO GERADOR ---
  // E-mail
  String _emailDomain = '@gmail.com';
  String _customDomain = '';
  
  // Senha
  double _pwdLength = 16;
  bool _pwdUpper = true;
  bool _pwdLower = true;
  bool _pwdNum = true;
  bool _pwdSym = true;

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

  void _copyToClipboardSecure(String text, String fieldName, {bool isSensitive = false}) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    
    String msg = '$fieldName copiado!';
    if (isSensitive) {
      msg += ' (Sumiço em 30s ⏱️)';
      Timer(const Duration(seconds: 30), () async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData != null && clipboardData.text == text) {
          Clipboard.setData(const ClipboardData(text: '')); 
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonPurple),
    );
  }

  // --- FUNÇÕES DE GERAÇÃO RÁPIDA (BOTÃO DO DADO) ---
  
  String _generateRandomPrefix() {
    const words = ['neon', 'cyber', 'synth', 'retro', 'wave', 'vapor', 'glitch', 'net', 'run'];
    final rnd = Random();
    final word = words[rnd.nextInt(words.length)];
    final number = rnd.nextInt(9999);
    return '$word$number';
  }

  void _quickGenerateEmail() {
    final prefix = _generateRandomPrefix();
    final domain = _emailDomain == 'Customizado' ? _customDomain : _emailDomain;
    final finalDomain = domain.startsWith('@') ? domain : (domain.isEmpty ? '@gmail.com' : '@$domain');
    _emailController.text = '$prefix$finalDomain';
  }

  void _quickGeneratePassword() {
    if (!_pwdUpper && !_pwdLower && !_pwdNum && !_pwdSym) {
      _pwdLower = true; // Segurança pra não bugar se o usuário desmarcar tudo
    }
    String chars = '';
    if (_pwdUpper) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_pwdLower) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_pwdNum) chars += '0123456789';
    if (_pwdSym) chars += '!@#\$%^&*()-_=+';
    
    final rnd = Random();
    final res = String.fromCharCodes(Iterable.generate(_pwdLength.toInt(), (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    _passwordController.text = res;
  }

  // --- POP-UPS DE CONFIGURAÇÃO (BOTÃO DA ENGRENAGEM) ---

  void _showEmailForgeDialog() {
    final prefixController = TextEditingController();
    final customDomainController = TextEditingController(text: _customDomain);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            backgroundColor: VaporwaveColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonCyan)),
            title: Text('CONFIGS: E-MAIL', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: prefixController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Prefixo opcional (Ex: player1)',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true, fillColor: VaporwaveColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButton<String>(
                    value: _emailDomain,
                    dropdownColor: VaporwaveColors.surfaceVariant,
                    isExpanded: true,
                    style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonYellow, fontSize: 14),
                    items: ['@gmail.com', '@hotmail.com', '@outlook.com', 'Customizado'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setStateBuilder(() => _emailDomain = val!),
                  ),
                  if (_emailDomain == 'Customizado') ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: customDomainController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => _customDomain = val,
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
              TextButton(onPressed: () => Navigator.pop(context), child: Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonPink))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonCyan),
                onPressed: () {
                  final prefix = prefixController.text.trim().isEmpty ? _generateRandomPrefix() : prefixController.text.trim();
                  final domain = _emailDomain == 'Customizado' ? _customDomain : _emailDomain;
                  final finalDomain = domain.startsWith('@') ? domain : (domain.isEmpty ? '@gmail.com' : '@$domain');
                  _emailController.text = '$prefix$finalDomain'; 
                  Navigator.pop(context);
                },
                child: Text('SALVAR E GERAR', style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showPasswordForgeDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) {
          return AlertDialog(
            backgroundColor: VaporwaveColors.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: VaporwaveColors.neonYellow)),
            title: Text('CONFIGS: SENHA', style: GoogleFonts.orbitron(color: VaporwaveColors.neonYellow)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamanho: ${_pwdLength.toInt()} caracteres', style: GoogleFonts.chakraPetch(color: Colors.white)),
                  Slider(
                    value: _pwdLength, min: 8, max: 64, divisions: 56,
                    activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => _pwdLength = val),
                  ),
                  CheckboxListTile(
                    title: const Text('Maiúsculas (A-Z)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _pwdUpper, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => _pwdUpper = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Minúsculas (a-z)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _pwdLower, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => _pwdLower = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Números (0-9)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _pwdNum, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => _pwdNum = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Símbolos (!@#\$%)', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _pwdSym, activeColor: VaporwaveColors.neonYellow,
                    onChanged: (val) => setStateBuilder(() => _pwdSym = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('FECHAR', style: TextStyle(color: VaporwaveColors.neonPink))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonYellow),
                onPressed: () {
                  _quickGeneratePassword(); 
                  Navigator.pop(context);
                },
                child: Text('SALVAR E GERAR', style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
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
      hasExpiration: _hasExpiration, 
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
    setState(() => _hasExpiration = true); 
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required String hintText, 
    required IconData icon, 
    bool isPassword = false, 
    VoidCallback? onGenerate, 
    VoidCallback? onSettings, 
    VoidCallback? onCopy
  }) {
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
              if (onGenerate != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(onPressed: onGenerate, icon: Icon(Icons.casino, color: VaporwaveColors.neonYellow), tooltip: 'Gerar Rápido'),
              ],
              if (onSettings != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(onPressed: onSettings, icon: Icon(Icons.settings_suggest, color: VaporwaveColors.neonCyan), tooltip: 'Configurações'),
              ],
              if (onCopy != null) ...[
                const SizedBox(width: AppSpacing.xs),
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
              
              _buildTextField(
                controller: _titleController, label: 'Identificador do Serviço', hintText: 'Ex: Steam, Banco...', icon: Icons.title
              ),
              
              _buildTextField(
                controller: _emailController, label: 'Usuário / E-mail', hintText: 'Digite ou gere um login', icon: Icons.person, 
                onGenerate: _quickGenerateEmail,
                onSettings: _showEmailForgeDialog, 
                onCopy: () => _copyToClipboardSecure(_emailController.text, 'Login')
              ),
              
              _buildTextField(
                controller: _passwordController, label: 'Senha de Acesso', hintText: 'Digite ou gere uma senha', icon: Icons.lock, isPassword: true, 
                onGenerate: _quickGeneratePassword, 
                onSettings: _showPasswordForgeDialog, 
                onCopy: () => _copyToClipboardSecure(_passwordController.text, 'Senha', isSensitive: true)
              ),
              
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
