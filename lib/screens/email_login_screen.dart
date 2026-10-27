import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/student_repository.dart';
import 'home_dashboard_screen.dart';
import 'register_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // --- TRANSIÇÃO DE FOTOS NO FUNDO ---
  List<String> get _backgroundImages => [
    'assets/imagem/masculino_e_feminino.png',
    'assets/imagem/dieta.png',
    'assets/imagem/hidratação.png',
  ];

  int _currentImageIndex = 0;
  late Timer _transitionTimer;
  // -----------------------------------

  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color cardBackground = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();

    // Configura o timer para alternar as imagens de fundo a cada 3.5 segundos
    _transitionTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _backgroundImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _transitionTimer.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF71717A), size: 20),
      filled: true,
      fillColor: cardBackground.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF27272A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final emailOrUser = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final students = StudentRepository.getStudents();

    try {
      final foundStudent = students.firstWhere(
        (s) =>
            s.nickname.toLowerCase() == emailOrUser ||
            s.name.toLowerCase() == emailOrUser,
      );

      if (foundStudent.password == password) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeDashboardScreen(userData: foundStudent.toMap()),
          ),
          (route) => false,
        );
      } else {
        _showError('Senha incorreta.');
      }
    } catch (e) {
      _showError('Usuário ou e-mail não encontrado.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Garante o preenchimento total de ponta a ponta
      body: Stack(
        children: [
          // 1. FUNDO: Transição suave de imagens cobrindo 100% da tela
          Positioned.fill(
            child: SizedBox.expand(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image.asset(
                  _backgroundImages[_currentImageIndex],
                  key: ValueKey<int>(_currentImageIndex),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFF121212));
                  },
                ),
              ),
            ),
          ),

          // 2. CAMADA DE ESCURECIMENTO (Gradiente para garantir leitura perfeita)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // 3. FRENTE: Conteúdo e Formulário de E-mail
          SafeArea(
            child: Column(
              children: [
                // Top Bar com Botão Voltar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new,
                              color: primaryGreen,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Voltar',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF27272A), height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          const Icon(
                            Icons.fitness_center,
                            size: 56,
                            color: primaryGreen,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Entrar com E-mail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Digite suas credenciais de acesso ao TreinoLivre',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Campo E-mail / Usuário
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'E-mail ou @apelido',
                              Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe seu e-mail ou apelido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Senha
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _inputDecoration(
                                  'Sua Senha',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF71717A),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Botão Entrar
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.black,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Entrar no App',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Link para cadastro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Ainda não tem uma conta? ',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
