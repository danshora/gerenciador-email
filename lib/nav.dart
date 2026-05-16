import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DashboardPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: VaporwaveColors.surface,
        selectedItemColor: VaporwaveColors.neonPink,
        unselectedItemColor: VaporwaveColors.neonCyan,
        // O const foi removido daqui para as cores poderem mudar livremente!
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_box, color: VaporwaveColors.neonPink),
            label: 'Nova Conta',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            activeIcon: Icon(Icons.list_alt, color: VaporwaveColors.neonPink),
            label: 'Gerenciador',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            activeIcon: Icon(Icons.settings_applications, color: VaporwaveColors.neonPink),
            label: 'Setup',
          ),
        ],
      ),
    );
  }
}
