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
                  _emailController.text = '$prefix$finalDomain'; // Gera e aplica
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
                  _quickGeneratePassword(); // Gera usando as novas configs
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

    _
