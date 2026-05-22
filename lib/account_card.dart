import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
  
  late List<String> _currentTags;
  bool _isEditing = false;
  bool _showPassword = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.account.title);
    _descController = TextEditingController(text: widget.account.description);
    _currentTags = List.from(widget.account.tags);

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
      _currentTags = List.from(widget.account.tags);
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
      isFavorite: widget.account.isFavorite,
      category: widget.account.category,
      tags: _currentTags,
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
      SnackBar(content: Text('$label copiado!', style: const TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonCyan),
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
                SelectableText(displayValue, style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          IconButton(onPressed: () => _copyField(value, label), icon: Icon(Icons.copy, color: VaporwaveColors.neonCyan, size: 18)),
          if (trailingAction != null && trailingIcon != null)
            IconButton(onPressed: trailingAction, icon: Icon(trailingIcon, color: VaporwaveColors.neonYellow, size: 18)),
        ],
      ),
    );
  }

  void _copyCredentials() {
    Clipboard.setData(ClipboardData(text: 'Login: ${widget.account.email}\nSenha: ${widget.account.password}'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Credenciais copiadas!', style: TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonCyan));
  }

  Widget _responsiveBottomRow({required String timeText, required AccountManager manager}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final counter = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Renovar:', style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonPink, fontSize: 12)),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<int>(
              icon: Icon(Icons.calendar_month, color: VaporwaveColors.neonCyan, size: 22),
              color: VaporwaveColors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: BorderSide(color: VaporwaveColors.neonPurple)),
              onSelected: (int days) => manager.setDays(widget.account.id, days),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 30, child: Text('1 Mês', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 365, child: Text('1 Ano', style: TextStyle(color: Colors.white))),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(value: 0, child: Text('Expirar Agora', style: TextStyle(color: VaporwaveColors.neonRed))),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Text(timeText, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 4,
          alignment: WrapAlignment.end,
          children: [
            if (_isEditing)
              IconButton(icon: Icon(Icons.check, color: VaporwaveColors.neonGreen), onPressed: _saveEdits)
            else
              IconButton(icon: Icon(Icons.edit, color: VaporwaveColors.neonYellow), onPressed: () => setState(() => _isEditing = true)),
            IconButton(icon: Icon(Icons.copy, color: VaporwaveColors.neonCyan), onPressed: _copyCredentials),
            IconButton(icon: Icon(Icons.delete, color: VaporwaveColors.neonRed), onPressed: () => manager.deleteAccount(widget.account.id)),
          ],
        );

        return constraints.maxWidth < 380
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [counter, const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerRight, child: actions)])
            : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [counter, actions]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AccountManager>();
    final isReady = widget.account.isReady;
    final statusColor = isReady ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed;
    final remaining = widget.account.remaining(DateTime.now());
    final timeText = remaining == Duration.zero ? 'Expirado' : _formatDuration(remaining);
    final isFav = widget.account.isFavorite;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: VaporwaveColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isFav ? VaporwaveColors.neonYellow : statusColor.withValues(alpha: 0.5), width: isFav ? 2.0 : 1.5),
        boxShadow: [BoxShadow(color: isFav ? VaporwaveColors.neonYellow.withValues(alpha: 0.2) : statusColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => manager.toggleFavorite(widget.account.id),
                icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? VaporwaveColors.neonYellow : VaporwaveColors.neonCyan.withValues(alpha: 0.5), size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _isEditing
                    ? TextField(controller: _titleController, style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 18), decoration: const InputDecoration(hintText: 'Nome', isDense: true))
                    : Text(widget.account.title, style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: () => manager.toggleStatus(widget.account.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: statusColor)),
                  child: Text(isReady ? 'Pronta' : 'Descartada', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _isEditing
              ? TextField(controller: _descController, style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: 'Notas', isDense: true), maxLines: 2)
              : Text(widget.account.description.isEmpty ? 'Sem descrição' : widget.account.description, style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 14)),
          Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),
          _credentialRow(icon: Icons.person, label: 'Login', value: widget.account.email),
          
          // --- VISUALIZAÇÃO DE TAGS (MODO LEITURA) ---
          if (!_isEditing && widget.account.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, bottom: AppSpacing.sm),
              child: Wrap(
                spacing: 6,
                children: widget.account.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: VaporwaveColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: VaporwaveColors.neonPurple, width: 1)),
                  child: Text(t, style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonCyan, fontSize: 11)),
                )).toList(),
              ),
            ),

          // --- SELEÇÃO DE TAGS (MODO EDIÇÃO) ---
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equipar Tags (Segure para apagar do app):', style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonYellow, fontSize: 11)),
                  const SizedBox(height: 4),
                  manager.savedTags.isEmpty 
                    ? Text('Nenhuma tag global criada ainda.', style: TextStyle(color: Colors.white38, fontSize: 12))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: manager.savedTags.map((tag) {
                          final isSelected = _currentTags.contains(tag);
                          return GestureDetector(
                            onLongPress: () => manager.removeGlobalTag(tag),
                            child: FilterChip(
                              label: Text(tag, style: TextStyle(color: isSelected ? VaporwaveColors.surfaceVariant : Colors.white, fontSize: 11)),
                              selected: isSelected,
                              selectedColor: VaporwaveColors.neonCyan,
                              backgroundColor: VaporwaveColors.surface,
                              side: BorderSide(color: isSelected ? VaporwaveColors.neonCyan : VaporwaveColors.neonPurple),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _currentTags.add(tag);
                                  } else {
                                    _currentTags.remove(tag);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                ],
              ),
            ),
          
          _credentialRow(icon: Icons.lock, label: 'Senha', value: widget.account.password, obscure: !_showPassword, trailingAction: () => setState(() => _showPassword = !_showPassword), trailingIcon: _showPassword ? Icons.visibility_off : Icons.visibility),
          Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),
          _responsiveBottomRow(timeText: timeText, manager: manager),
        ],
      ),
    );
  }
}
