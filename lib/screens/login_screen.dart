import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import necessário para consultar o Firestore

import 'email_login_screen.dart';
import 'home_dashboard_screen.dart';
import 'diagnosis.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<String> get _backgroundImages => [
    'assets/imagem/masculino_e_feminino.png',
    'assets/imagem/dieta.png',
    'assets/imagem/hidratação.png',
  ];

  int _currentImageIndex = 0;
  late Timer _transitionTimer;

  bool _acceptedTerms = false;
  bool _showTermsError = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instância do Firestore

  static const Color primaryGreen = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _showLegalModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Li e Compreendi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _verificarEProsseguir(VoidCallback acaoProxima) {
    if (!_acceptedTerms) {
      setState(() {
        _showTermsError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deve ler e aceitar os Termos de Uso e a Política de Privacidade.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _showTermsError = false;
    });
    acaoProxima();
  }

  Future<void> _processarAtletaSocial({
    required User firebaseUser,
    required String name,
    required String email,
    required String? photoUrl,
    required String provider,
  }) async {
    if (!mounted) return;

    try {
      // 1. Consulta no Firebase Firestore se já existe um documento de diagnóstico 360 para este UID
      final docRef = _firestore
          .collection('diagnosticos_360')
          .doc(firebaseUser.uid);
      final docSnapshot = await docRef.get();

      bool hasCompletedDiagnosis = false;
      Map<String, dynamic> studentData = {
        'name': name,
        'nickname': email,
        'email': email,
        'profileImageUrl': photoUrl ?? '',
      };

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // Verifica se o status está marcado como 'respondido'
        if (data['status'] == 'respondido') {
          hasCompletedDiagnosis = true;
          studentData.addAll(data); // Mescla com os dados salvos anteriormente
        }
      }

      if (!mounted) return;

      if (hasCompletedDiagnosis) {
        // Se já preencheu, vai direto para a Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryGreen,
            content: Text(
              'Bem-vindo de volta ao TreinoLivre, $name!',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeDashboardScreen(userData: studentData),
          ),
          (route) => false,
        );
      } else {
        // Se NÃO preencheu ou é a primeira vez, força a tela do 360°
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              'Por favor, responda ao Diagnóstico 360° para continuar.',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Diagnosis360Screen(
              isEditing: false,
              existingData: studentData,
              onSubmit: (completedData) async {
                // 2. Salva os dados respondidos no Firebase Firestore vinculados ao UID do utilizador
                await _firestore
                    .collection('diagnosticos_360')
                    .doc(firebaseUser.uid)
                    .set({
                      ...completedData,
                      'status': 'respondido',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomeDashboardScreen(userData: completedData),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar dados no Firebase: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        final String email = user.email ?? googleUser.email;
        final String name =
            user.displayName ?? googleUser.displayName ?? 'Atleta Google';
        final String? photoUrl = user.photoURL ?? googleUser.photoUrl;

        await _processarAtletaSocial(
          firebaseUser: user,
          name: name,
          email: email,
          photoUrl: photoUrl,
          provider: 'Google',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao autenticar com o Google: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleMetaSignIn(String redeSocial) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200)",
        );

        // Se autenticado com sucesso pelo Facebook, pegamos o utilizador atual do Firebase Auth
        User? user = _firebaseAuth.currentUser;
        if (user == null) {
          // Caso precise de credencial do facebook no firebase, certifique-se de logar no firebaseAuth se necessário
          // Por segurança, garantimos que temos um utilizador ativo
        }

        if (user != null) {
          final String name = userData['name'] ?? 'Atleta $redeSocial';
          final String userEmail =
              userData['email'] ??
              '${userData['id'] ?? "atleta"}@${redeSocial.toLowerCase()}.com';
          final String? photoUrl = userData['picture']?['data']?['url'];

          await _processarAtletaSocial(
            firebaseUser: user,
            name: name,
            email: userEmail,
            photoUrl: photoUrl,
            provider: redeSocial,
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Autenticação com $redeSocial cancelada.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro no login ($redeSocial): ${result.message ?? "Falha de conexão"}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao conectar com $redeSocial: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SizedBox.expand(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1200),
                child: Image.asset(
                  _backgroundImages[_currentImageIndex],
                  key: ValueKey<int>(_currentImageIndex),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TreinoLivre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Evolua todos os dias, sem barreiras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 28),
                  _SocialLoginButton(
                    icon: Icons.g_mobiledata,
                    text: 'Continuar com o Google',
                    color: Colors.white,
                    textColor: Colors.black,
                    onPressed: () =>
                        _verificarEProsseguir(() => _handleGoogleSignIn()),
                  ),
                  const SizedBox(height: 12),
                  _SocialLoginButton(
                    icon: Icons.facebook,
                    text: 'Continuar com o Facebook',
                    color: const Color(0xFF1877F2),
                    textColor: Colors.white,
                    onPressed: () => _verificarEProsseguir(
                      () => _handleMetaSignIn('Facebook'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SocialLoginButton(
                    icon: Icons.camera_alt,
                    text: 'Continuar com o Instagram',
                    color: const Color(0xFFE1306C),
                    textColor: Colors.white,
                    onPressed: () => _verificarEProsseguir(
                      () => _handleMetaSignIn('Instagram'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SocialLoginButton(
                    icon: Icons.email_outlined,
                    text: 'Continuar com E-mail',
                    color: const Color(0xFF2D2B38),
                    textColor: Colors.white,
                    onPressed: () => _verificarEProsseguir(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailLoginScreen(),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showTermsError
                            ? Colors.redAccent
                            : const Color(0xFF27272A),
                        width: _showTermsError ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: Checkbox(
                            value: _acceptedTerms,
                            activeColor: primaryGreen,
                            checkColor: Colors.black,
                            side: const BorderSide(color: Color(0xFF71717A)),
                            onChanged: (val) {
                              setState(() {
                                _acceptedTerms = val ?? false;
                                if (_acceptedTerms) _showTermsError = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text(
                                'Concordo com os ',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showLegalModal(
                                  context,
                                  'Termos de Uso',
                                  '1. NATUREZA DA PLATAFORMA: O TreinoLivre é uma ferramenta tecnológica autônoma de suporte fitness.\n\n2. ISENÇÃO: O uso de treinos é de inteira responsabilidade do utilizador.',
                                ),
                                child: const Text(
                                  'Termos de Uso',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                ' e a ',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showLegalModal(
                                  context,
                                  'Política de Privacidade (LGPD)',
                                  '1. DADOS: Coletamos dados estritamente para uso operacional.\n\n2. ARMAZENAMENTO: Armazenados primariamente no seu dispositivo.',
                                ),
                                child: const Text(
                                  'Política de Privacidade',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                '.',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
