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

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AccountManager>();
    
    var displayList = manager.searchAccounts(_searchController.text.trim());
    
    if (_selectedTag != 'Todas') {
      displayList = displayList.where((account) => account.tags.contains(_selectedTag)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GERENCIADOR',
          style: GoogleFonts.orbitron(
            color: VaporwaveColors.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: neonGlowCyan,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
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
                      value: manager.savedTags.contains(_selectedTag) || _selectedTag == 'Todas' 
                          ? _selectedTag 
                          : 'Todas',
                      dropdownColor: VaporwaveColors.surfaceVariant,
                      icon: Icon(Icons.label, color: VaporwaveColors.neonPink),
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTag = newValue;
                          });
                        }
                      },
                      items: ['Todas', ...manager.savedTags].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'Todas' ? 'TAGS: TODAS' : '# $value'),
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
                    ? Center(
                        child: Text(
                          'Nenhum registro encontrado.',
                          style: GoogleFonts.chakraPetch(color: Colors.white38, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final account = displayList[index];
                          return AccountCard(
                            key: ValueKey(account.id),
                            account: account,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
