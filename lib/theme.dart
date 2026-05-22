import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account.dart';
import 'account_manager.dart';
import 'theme.dart'; // <- ESTA É A LINHA QUE ESTAVA FALTANDO!

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
      hasExpiration: widget.account.hasExpiration,
      category: widget.account.category,
      tags: _currentTags,
      createdAt: widget.account.createdAt,
      updatedAt: DateTime.now(),
      expiresAt: widget.account.expiresAt,
    );
    context.read<AccountManager>().updateAccount(updated);
    setState(() => _isEditing = false);
  }

  void _copyToClipboardSecure(String text, String label, {bool isSensitive = false}) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    
    String msg = '$label copiado!';
    if (isSensitive) {
      msg += ' (Auto-limpeza em 30s)';
      Timer(const Duration(seconds: 30), () async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData != null && clipboardData.text == text) {
          Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: VaporwaveColors.neonCyan),
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
          IconButton(onPressed: () => _copyToClipboardSecure(value, label, isSensitive: obscure), icon: Icon(Icons.copy, color: VaporwaveColors.neonCyan, size: 18)),
          if (trailingAction != null && trailingIcon != null)
            IconButton(onPressed: trailingAction, icon: Icon(trailingIcon, color: VaporwaveColors.neonYellow, size: 18)),
        ],
      ),
    );
  }

  Widget _responsiveBottomRow({required String timeText, required AccountManager manager}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final counter = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.account.hasExpiration ? 'Renovar:' : 'Status:', style: GoogleFonts.chakraPetch(color: VaporwaveColors.neonPink, fontSize: 12)),
            const SizedBox(width: AppSpacing.xs),
            
            if (widget.account.hasExpiration) 
              PopupMenuButton<int>(
                icon: Icon(Icons.calendar_month, color: VaporwaveColors.neonCyan, size: 22),
                color: VaporwaveColors.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: BorderSide(color: VaporwaveColors.neonPurple)),
                onSelected: (int val) async {
                  if (val == -1) {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: VaporwaveColors.neonCyan,
                              onPrimary: VaporwaveColors.surface,
                              surface: VaporwaveColors.surfaceVariant,
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: VaporwaveColors.surfaceVariant,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      final days = picked.difference(DateTime.now()).inDays + 1;
                      manager.setDays(widget.account.id, days);
                    }
                  } else {
                    manager.setDays(widget.account.id, val);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 7, child: Text('1 Semana', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 30, child: Text('1 Mês', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 365, child: Text('1 Ano', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: -1, child: Text('Customizado...', style: TextStyle(color: Colors.white))),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(value: 0, child: Text('Expirar Agora', style: TextStyle(color: VaporwaveColors.neonRed))),
                ],
              ),
            
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100),
              child: Text(
                widget.account.hasExpiration ? timeText : '
