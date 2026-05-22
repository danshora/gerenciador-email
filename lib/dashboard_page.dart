import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_manager.dart';
import 'account_card.dart';
import 'theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _searchController = TextEditingController();
  String _selectedTag = 'Todas'; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTagDialog(BuildContext context, AccountManager manager) {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VaporwaveColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: VaporwaveColors.neonPink, width: 2),
        ),
        title: Text('FORJAR NOVA TAG', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan)),
        content: TextField(
          controller: tagController,
          style: const TextStyle(color: Colors.white),
          maxLength: 15,
          decoration: InputDecoration(
            hintText: 'Ex: GAMES',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: VaporwaveColors.surface,
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VaporwaveColors.neonPurple)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VaporwaveColors.neonCyan)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: TextStyle(color: VaporwaveColors.neonPink)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VaporwaveColors.neonCyan),
            onPressed: () {
              final val = tagController.text.trim();
              if (val.isNotEmpty) {
                final success = manager.addGlobalTag(val);
                Navigator.pop(context);
                if (success) {
                  setState(() => _selectedTag = val.toUpperCase());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(manager.isPremium ? 'Limite de 10 tags Premium atingido!' : 'Limite Free de 3 tags atingido. Assine o Premium!', style: const TextStyle(color: Colors.white)),
                      backgroundColor: VaporwaveColors.neonRed,
                    ),
                  );
                }
              }
            },
            child: Text('SALVAR', style: TextStyle(color: VaporwaveColors.surfaceVariant, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AccountManager>();
    var displayList = manager.searchAccounts(_searchController.text.trim());
    
    if (_selectedTag != 'Todas') {
      displayList = displayList.where((account) => account.tags.contains(_selectedTag)).toList();
    }

    // Montando a lista do menu
    List<String> dropdownOptions = ['Todas', ...manager.savedTags, '+ Nova Tag'];

    return Scaffold(
      appBar: AppBar(
        title: Text('GERENCIADOR', style: GoogleFonts.orbitron(color: VaporwaveColors.neonCyan, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(boxShadow: neonGlowCyan, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}), 
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar credenciais...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        prefixIcon: Icon(Icons.search, color: VaporwaveColors.neonCyan),
                        filled: true,
                        fillColor: VaporwaveColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: VaporwaveColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: VaporwaveColors.neonPink, width: 1.5),
                    boxShadow: neonGlowPink,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownOptions.contains(_selectedTag) ? _selectedTag : 'Todas',
                      dropdownColor: VaporwaveColors.surfaceVariant,
                      icon: Icon(Icons.label, color: VaporwaveColors.neonPink),
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        if (newValue == '+ Nova Tag') {
                          _showAddTagDialog(context, manager);
                        } else if (newValue != null) {
                          setState(() {
                            _selectedTag = newValue;
                          });
                        }
                      },
                      items: dropdownOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'Todas' ? 'TAGS: TODAS' : 
                            value == '+ Nova Tag' ? '+ ADD TAG' : '# $value',
                            style: value == '+ Nova Tag' ? TextStyle(color: VaporwaveColors.neonYellow) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: manager.isLoading
                ? Center(child: CircularProgressIndicator(color: VaporwaveColors.neonCyan))
                : displayList.isEmpty
                    ? Center(child: Text('Nenhum registro encontrado.', style: GoogleFonts.chakraPetch(color: Colors.white38, fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          return AccountCard(key: ValueKey(displayList[index].id), account: displayList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
