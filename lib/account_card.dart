import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';
import '../providers/account_manager.dart';
import '../theme.dart';

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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Aumentar 1 dia',
            ),
          ],
        );

        final actions = Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.check, color: VaporwaveColors.neonGreen),
                onPressed: _saveEdits,
                tooltip: 'Salvar',
              )
            else
              IconButton(
                icon: const Icon(Icons.edit, color: VaporwaveColors.neonYellow),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Editar',
              ),
            IconButton(
              icon: const Icon(Icons.copy, color: VaporwaveColors.neonCyan),
              onPressed: _copyCredentials,
              tooltip: 'Copiar credenciais',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: VaporwaveColors.neonRed),
              onPressed: () => manager.deleteAccount(widget.account.id),
              tooltip: 'Excluir',
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              counter,
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            counter,
            actions,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AccountManager>();
    final isReady = widget.account.isReady;
    final statusColor = isReady ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed;
    final statusText = isReady ? 'Pronta para uso' : 'Descartada';
    final remaining = widget.account.remaining(DateTime.now());
    final timeText = remaining == Duration.zero ? 'Expirado' : _formatDuration(remaining);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: VaporwaveColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Status Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _titleController,
                        style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: 'Nome da Conta',
                          isDense: true,
                        ),
                      )
                    : Text(
                        widget.account.title,
                        style: GoogleFonts.orbitron(
                          color: VaporwaveColors.neonCyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              InkWell(
                onTap: () => manager.toggleStatus(widget.account.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Description
          _isEditing
              ? TextField(
                  controller: _descController,
                  style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Descrição / Notas',
                    isDense: true,
                  ),
                  maxLines: 2,
                )
              : Text(
                  widget.account.description.isEmpty ? 'Sem descrição' : widget.account.description,
                  style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 14),
                ),
          
          const Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),

          _credentialRow(icon: Icons.person, label: 'E-mail / Login', value: widget.account.email),
          _credentialRow(
            icon: Icons.lock,
            label: 'Senha',
            value: widget.account.password,
            obscure: !_showPassword,
            trailingAction: () => setState(() => _showPassword = !_showPassword),
            trailingIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
          ),

          const Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),

          // Cronômetro e ações
          _responsiveBottomRow(timeText: timeText, manager: manager),
        ],
      ),
    );
  }
}
