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
  final _tagInputController = TextEditingController();
  
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
    _tagInputController.dispose();
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

  void _addTag() {
    final newTag = _tagInputController.text.trim();
    if (newTag.isEmpty) return;
    
    final manager = context.read<AccountManager>();
    
    if (_currentTags.contains(newTag)) return;

    if (_currentTags.length < 3) {
      bool foiSalvaGlobal = manager.addGlobalTag(newTag);
      
      setState(() {
        _currentTags.add(newTag);
        _tagInputController.clear();
      });

      if (!foiSalvaGlobal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tag inserida no card, mas limite de 3 tags na memória atingido!', style: TextStyle(color: Colors.white)),
            backgroundColor: VaporwaveColors.neonYellow,
          ),
        );
      }
    } else {
      _avisoLimite();
    }
  }

  void _useQuickTag(String tag) {
    if (_currentTags.contains(tag)) return;
    if (_currentTags.length < 3) {
      setState(() {
        _currentTags.add(tag);
      });
    } else {
      _avisoLimite();
    }
  }

  void _avisoLimite() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Limite de 3 tags por conta atingido. (Premium: até 10)', style: TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonPink,
      ),
    );
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
            icon: Icon(Icons.copy, color: VaporwaveColors.neonCyan, size: 18),
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
      SnackBar(
        content: const Text('Credenciais copiadas!', style: TextStyle(color: Colors.white)),
        backgroundColor: VaporwaveColors.neonCyan,
      ),
    );
  }

  Widget _responsiveBottomRow({required String timeText, required AccountManager manager}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        final counter = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Renovar:',
              style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonPink, fontSize: 12),
            ),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<int>(
              icon: Icon(Icons.calendar_month, color: VaporwaveColors.neonCyan, size: 22),
              tooltip: 'Escolher duração',
              color: VaporwaveColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: BorderSide(color: VaporwaveColors.neonPurple),
              ),
              onSelected: (int days) {
                manager.setDays(widget.account.id, days);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text('1 Dia', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 3, child: Text('3 Dias', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 7, child: Text('7 Dias', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 15, child: Text('15 Dias', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 30, child: Text('1 Mês (30)', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 60, child: Text('2 Meses (60)', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 365, child: Text('1 Ano', style: TextStyle(color: Colors.white))),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(value: 0, child: Text('Expirar Agora', style: TextStyle(color: VaporwaveColors.neonRed))),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Text(
                timeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
                icon: Icon(Icons.check, color: VaporwaveColors.neonGreen),
                onPressed: _saveEdits,
                tooltip: 'Salvar',
              )
            else
              IconButton(
                icon: Icon(Icons.edit, color: VaporwaveColors.neonYellow),
                onPressed: () {
                  setState(() {
                    _currentTags = List.from(widget.account.tags);
                    _isEditing = true;
                  });
                },
                tooltip: 'Editar',
              ),
            IconButton(
              icon: Icon(Icons.copy, color: VaporwaveColors.neonCyan),
              onPressed: _copyCredentials,
              tooltip: 'Copiar credenciais',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: VaporwaveColors.neonRed),
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
    final manager = context.watch<AccountManager>();
    final isReady = widget.account.isReady;
    final statusColor = isReady ? VaporwaveColors.neonGreen : VaporwaveColors.neonRed;
    final statusText = isReady ? 'Pronta para uso' : 'Descartada';
    final remaining = widget.account.remaining(DateTime.now());
    final timeText = remaining == Duration.zero ? 'Expirado' : _formatDuration(remaining);
    final isFav = widget.account.isFavorite;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: VaporwaveColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isFav ? VaporwaveColors.neonYellow : statusColor.withValues(alpha: 0.5), 
          width: isFav ? 2.0 : 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: isFav ? VaporwaveColors.neonYellow.withValues(alpha: 0.2) : statusColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => manager.toggleFavorite(widget.account.id),
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? VaporwaveColors.neonYellow : VaporwaveColors.neonCyan.withValues(alpha: 0.5),
                  size: 24,
                ),
                tooltip: isFav ? 'Remover dos favoritos' : 'Fixar no topo',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _titleController,
                        style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 18),
                        decoration: const InputDecoration(hintText: 'Nome da Conta', isDense: true),
                      )
                    : Text(
                        widget.account.title,
                        style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontSize: 18, fontWeight: FontWeight.bold),
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
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _isEditing
              ? TextField(
                  controller: _descController,
                  style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Descrição / Notas', isDense: true),
                  maxLines: 2,
                )
              : Text(
                  widget.account.description.isEmpty ? 'Sem descrição' : widget.account.description,
                  style: GoogleFonts.chakraPetch(color: Colors.white70, fontSize: 14),
                ),
          Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),
          _credentialRow(icon: Icons.person, label: 'E-mail / Login', value: widget.account.email),
          
          if (!_isEditing && widget.account.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, bottom: AppSpacing.sm),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.account.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VaporwaveColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: VaporwaveColors.neonPurple, width: 1),
                  ),
                  child: Text(t, style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonCyan, fontSize: 11)),
                )).toList(),
              ),
            ),

          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (manager.savedTags.isNotEmpty) ...[
                    Text('Sua Biblioteca Global (Clique para Equipar / Segure para Deletar):', 
                      style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonCyan, fontSize: 11)
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: manager.savedTags.map((st) => GestureDetector(
                        onLongPress: () => manager.removeGlobalTag(st), 
                        child: ActionChip(
                          label: Text(st, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: VaporwaveColors.surface,
                          side: BorderSide(color: VaporwaveColors.neonCyan.withValues(alpha: 0.4)),
                          onPressed: () => _useQuickTag(st), 
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Text('Registrar Nova Tag (${_currentTags.length}/3):', 
                    style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonYellow, fontSize: 11)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: TextField(
                            controller: _tagInputController,
                            style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Escreva e clique em + ...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              filled: true,
                              fillColor: VaporwaveColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: VaporwaveColors.neonCyan),
                        onPressed: _addTag,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 35),
                      )
                    ],
                  ),
                  if (_currentTags.isNotEmpty) const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _currentTags.map((t) => InputChip(
                      label: Text(t, style: GoogleFonts.chakraPetch(color: Colors.white, fontSize: 11)),
                      backgroundColor: VaporwaveColors.surfaceVariant,
                      deleteIconColor: VaporwaveColors.neonRed,
                      side: BorderSide(color: VaporwaveColors.neonPink),
                      onDeleted: () {
                        setState(() {
                          _currentTags.remove(t);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
          
          _credentialRow(
            icon: Icons.lock,
            label: 'Senha',
            value: widget.account.password,
            obscure: !_showPassword,
            trailingAction: () => setState(() => _showPassword = !_showPassword),
            trailingIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
          ),
          Divider(color: VaporwaveColors.neonPurple, height: AppSpacing.lg),
          _responsiveBottomRow(timeText: timeText, manager: manager),
        ],
      ),
    );
  }
}
