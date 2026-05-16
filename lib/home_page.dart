import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/account.dart';
import '../providers/account_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _TagChips extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _TagChips({required this.tags, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags.map((t) {
        final isSelected = selected.contains(t);
        return FilterChip(
          label: Text(t),
          selected: isSelected,
          onSelected: (_) => onToggle(t),
          showCheckmark: false,
          side: BorderSide(color: (isSelected ? VaporwaveColors.neonPink : VaporwaveColors.neonPurple).withValues(alpha: 0.9)),
          backgroundColor: VaporwaveColors.surface,
          selectedColor: VaporwaveColors.surfaceVariant,
          labelStyle: GoogleFonts.chakraPetch(
            color: isSelected ? VaporwaveColors.neonCyan : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );
      }).toList(),
    );
  }
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _glowController;

  final Set<String> _selectedTags = {'Outros'};

  static const List<String> _availableTags = [
    'Jogos',
    'Streaming',
    'Trabalho',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _generateRandomString(int length) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  String _generateRandomEmail() {
    const words = ['neon', 'cyber', 'synth', 'retro', 'wave', 'vapor', 'glitch'];
    final rnd = Random();
    final word = words[rnd.nextInt(words.length)];
    final number = rnd.nextInt(9999);
    return '${word}${number}@gmail.com';
  }

  void _copyToClipboard(String text, String fieldName) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copiado!', style: const TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveAccount() {
    if (_titleController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios', style: TextStyle(color: Colors.white)),
          backgroundColor: VaporwaveColors.neonRed,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final tags = _selectedTags.isEmpty ? <String>['Outros'] : _selectedTags.toList();
    final account = Account(
      title: _titleController.text,
      email: _emailController.text,
      password: _passwordController.text,
      description: '',
      daysLeft: 30,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      isReady: true,
      // Mantém compatibilidade com o filtro do Gerenciador.
      category: tags.first,
      tags: tags,
    );

    context.read<AccountManager>().addAccount(account);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta salva no cyber-espaço!', style: TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonGreen,
      ),
    );

    _titleController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedTags
        ..clear()
        ..add('Outros');
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onGenerate,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: neonGlowCyan,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: TextField(
                    controller: controller,
                    obscureText: isPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(icon, color: VaporwaveColors.neonCyan),
                      hintText: hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: VaporwaveColors.surface,
                    ),
                  ),
                ),
              ),
              if (onGenerate != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.casino, color: VaporwaveColors.neonYellow),
                  tooltip: 'Gerar Aleatório',
                ),
              ],
              if (onCopy != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, color: VaporwaveColors.neonPink),
                  tooltip: 'Copiar',
                ),
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
                    return Text(
                      'NOVA CONTA',
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: VaporwaveColors.neonPink,
                        shadows: [
                          Shadow(
                            color: VaporwaveColors.neonPink.withValues(alpha: 0.5 + (_glowController.value * 0.5)),
                            blurRadius: 10 + (_glowController.value * 15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              _buildTextField(
                controller: _titleController,
                label: 'Nome da Conta',
                hintText: 'Digite nome',
                icon: Icons.title,
              ),
              
              _buildTextField(
                controller: _emailController,
                label: 'E-mail ou Login',
                hintText: 'Digite e-mail',
                icon: Icons.person,
                onGenerate: () {
                  _emailController.text = _generateRandomEmail();
                },
                onCopy: () => _copyToClipboard(_emailController.text, 'Login'),
              ),
              
              _buildTextField(
                controller: _passwordController,
                label: 'Senha',
                hintText: 'Digite senha',
                icon: Icons.lock,
                isPassword: true,
                onGenerate: () {
                  _passwordController.text = _generateRandomString(16);
                },
                onCopy: () => _copyToClipboard(_passwordController.text, 'Senha'),
              ),

              Text(
                'Tags',
                style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TagChips(
                tags: _availableTags,
                selected: _selectedTags,
                onToggle: (t) {
                  setState(() {
                    if (_selectedTags.contains(t)) {
                      _selectedTags.remove(t);
                    } else {
                      _selectedTags.add(t);
                    }

                    // Garante pelo menos 1 tag.
                    if (_selectedTags.isEmpty) {
                      _selectedTags.add('Outros');
                    }
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: neonGlowPink,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: ElevatedButton(
                      onPressed: _saveAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaporwaveColors.surfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        side: BorderSide(
                          color: VaporwaveColors.neonPink.withValues(alpha: 0.8 + (_glowController.value * 0.2)),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'SALVAR CONTA',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: VaporwaveColors.neonPink,
                          letterSpacing: 2,
                        ),
                      ),
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
