import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import 'nav.dart';
import 'theme.dart';
import 'account_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountManager()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VaporManagerApp(),
    ),
  );
}

class VaporManagerApp extends StatelessWidget {
  const VaporManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças de tema para redesenhar o app inteiro!
    context.watch<ThemeProvider>(); 
    
    return MaterialApp(
      title: 'Vapor Manager',
      debugShowCheckedModeBanner: false,
      theme: darkTheme, // O darkTheme agora é dinâmico!
      // Envolvemos o App na Biometria
      home: const BiometricGate(child: AppNavigation()),
    );
  }
}

// --- SISTEMA DE TELA DE BLOQUEIO BIOMÉTRICO ---
class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      // Se o celular não tem biometria configurada, deixa passar
      if (!canAuthenticate) {
        setState(() => _isAuthenticated = true);
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Acesse o cofre cibernético',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      setState(() => _isAuthenticated = didAuthenticate);
    } catch (e) {
      // Em caso de erro severo, libera para não travar o app para sempre
      setState(() => _isAuthenticated = true); 
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) return widget.child;

    return Scaffold(
      backgroundColor: VaporwaveColors.background,
      body: Center(
        child: _isAuthenticating
            ? CircularProgressIndicator(color: VaporwaveColors.neonPink)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: VaporwaveColors.neonPink),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('DESBLOQUEAR SISTEMA', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }
}
