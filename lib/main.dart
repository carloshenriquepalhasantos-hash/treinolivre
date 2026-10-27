import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/login_screen.dart';
import 'screens/home_dashboard_screen.dart';

void main() async {
  // Garante que os bindings do Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase para o app
  await Firebase.initializeApp();

  // Inicializa o suporte ao banco de dados SQLite no Windows e Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Deixa a barra de status transparente para casar com o design escuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreinoLivre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // Monitoriza o estado da sessão do utilizador em tempo real
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Ecrã de carregamento enquanto valida a sessão guardada
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0E0B),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              ),
            );
          }

          // Se já existe sessão ativa, vai direto para o painel principal
          if (snapshot.hasData) {
            return const HomeDashboardScreen();
          }

          // Caso contrário, apresenta o ecrã de login
          return const LoginScreen();
        },
      ),
      routes: {
        '/dashboard': (context) => const HomeDashboardScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
