import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Imports corrigidos para a pasta raiz
import 'account_manager.dart';
import 'account_card.dart';
import 'theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  final List<String> _categories = ['Todas', 'Jogos', 'Streaming', 'Trabalho', 'Outros'];

  @override
  Widget build(BuildContext context) {
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
      body: Consumer<AccountManager>(
        builder: (context, manager, child) {
          if (manager.isLoading) {
            return const Center(child: CircularProgressIndicator(color: VaporwaveColors.neonPink));
          }

          final accounts = manager.accounts.where((acc) {
            final matchesSearch = acc.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  acc.email.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory = _selectedCategory == 'Todas' || acc.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Search and Filter
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: neonGlowCyan,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Buscar contas...',
                            prefixIcon: const Icon(Icons.search, color: VaporwaveColors.neonCyan),
                            filled: true,
                            fillColor: VaporwaveColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: VaporwaveColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: VaporwaveColors.neonPurple),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: VaporwaveColors.surfaceVariant,
                            icon: const Icon(Icons.arrow_drop_down, color: VaporwaveColors.neonPink),
                            style: GoogleFonts.chakraPetch(color: Colors.white),
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedCategory = newValue);
                              }
                            },
                            items: _categories.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // List View
                Expanded(
                  child: accounts.isEmpty
                      ? Center(
                          child: Text(
                            'NENHUMA CONTA ENCONTRADA',
                            style: GoogleFonts.orbitron(color: VaporwaveColors.neonPurple, fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            return AccountCard(account: accounts[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
