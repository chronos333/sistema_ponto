import 'package:flutter/material.dart';

import 'screens/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SistemaPontoApp());
}

class SistemaPontoApp extends StatelessWidget {
  const SistemaPontoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Ponto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF174A78),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const LoginPage(),
    );
  }
}