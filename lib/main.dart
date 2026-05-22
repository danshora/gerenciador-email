import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'account_manager.dart';
import 'theme.dart';
import 'nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaporManagerApp());
}

class VaporManagerApp extends StatelessWidget {
  const VaporManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountManager()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Vapor Manager',
            debugShowCheckedModeBanner: false,
            // A CORREÇÃO ESTÁ AQUI: agora o tema muda em tempo real
            theme: themeProvider.getThemeData(), 
            home: const AppNavigation(),
          );
        },
      ),
    );
  }
}
