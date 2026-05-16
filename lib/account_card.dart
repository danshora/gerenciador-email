import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports corrigidos
import 'account.dart';
import 'account_manager.dart';
import 'theme.dart';

class AccountCard extends StatefulWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isEditing = false;
  bool _showPassword = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.account.title);
    _descController = TextEditingController(text: widget.account.description);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AccountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _titleController.text = widget.account.title;
      _descController.text = widget.account.description;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveEdits() {
    final updated = Account(
      id: widget.account.id,
      title: _titleController.text,
      email: widget.account.email,
      password: widget.account.password,
      description: _descController.text,
      daysLeft: widget.account.daysLeft,
      isReady: widget.account.isReady,
      category: widget.account.category,
      tags: widget.account.tags,
      createdAt: widget.account.createdAt,
      updatedAt: DateTime.now(),
      expiresAt: widget.account.expiresAt,
    );
    context.read<AccountManager>().updateAccount(updated);
    setState(() {
      _isEditing = false;
    });
  }

  void _copyField(String value, String label) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!', style: const TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${days}d ${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  Widget _credentialRow({required IconData icon, required String label, required String value, bool obscure = false, VoidCallback? trailingAction, IconData? trailingIcon}) {
    final int obscuredLen = value.isEmpty ? 0 : (value.length.clamp(6, 24) as int);
    final displayValue = obscure ? ('•' * obscuredLen) : value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: VaporwaveColors.neonPink, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 2),
                SelectableText(
                  displayValue,
                  style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyField(value, label),
            icon: const Icon(Icons.copy, color: VaporwaveColors.neonCyan, size: 18),
            tooltip: 'Copiar',
          ),
          if (trailingAction != null && trailingIcon != null)
            IconButton(
              onPressed: trailingAction,
              icon: Icon(trailingIcon, color: VaporwaveColors.neonYellow, size: 18),
              tooltip: 'Mostrar/ocultar',
            ),
        ],
      ),
    );
  }

  void _copyCredentials() {
    final text = 'Login: ${widget.account.email}\nSenha: ${widget.account.password}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credenciais copiadas!', style: TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonCyan,
      ),
    );
  }

  Widget _responsiveBottomRow({
    required String timeText,
    required AccountManager manager,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        final counter = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cronômetro:',
              style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonPink, fontSize: 12),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: VaporwaveColors.neonCyan, size: 20),
              onPressed: () => manager.decrementDays(widget.account.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Diminuir 1 dia',
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 132),
              child: Text(
                timeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: VaporwaveColors.neonCyan, size: 20),
              onPressed: () => manager.incrementDays(widget.account.id),
