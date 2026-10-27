import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../repositories/student_repository.dart';
import '../models/student_model.dart';
import '../services/firebase_service.dart'; // <-- Importado para sincronização com o Firebase
import 'home_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialProfileImageUrl;

  const RegisterScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialProfileImageUrl,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedGender;

  bool _acceptedTerms = false;
  bool _showTermsError = false;

  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);

  final List<String> _profanityList = [
    'teste',
    'admin',
    'moderador',
    'sexo',
    'porra',
    'caralho',
    'merda',
    'puta',
    'desgraça',
    'cu',
    'bosta',
    'cacete',
    'fdp',
    'pqp',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _containsProfanity(String text) {
    final lowerText = text.toLowerCase().trim();
    for (var word in _profanityList) {
      if (lowerText.contains(word)) return true;
    }
    return false;
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF71717A), size: 20),
      filled: true,
      fillColor: cardBackground,
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

  void _showLegalModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    'CRIAR CONTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF71717A),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bem-vindo ao TreinoLivre 💪',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Preencha seus dados para personalizar sua evolução.',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Nome completo *',
                          Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome completo';
                          }
                          if (_containsProfanity(value)) {
                            return 'Termo não permitido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Nome de usuário (@apelido)',
                          Icons.alternate_email,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Seu E-mail *',
                          Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: _inputDecoration(
                          'Telefone / WhatsApp',
                          Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _birthDateController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          DateInputFormatter(),
                        ],
                        decoration: _inputDecoration(
                          'Data de nascimento (DD/MM/AAAA)',
                          Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        dropdownColor: cardBackground,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF71717A),
                        ),
                        decoration: _inputDecoration(
                          'Gênero',
                          Icons.wc_outlined,
                        ),
                        items: ['Masculino', 'Feminino', 'Outro']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                'Peso (kg) *',
                                Icons.fitness_center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                HeightInputFormatter(),
                              ],
                              decoration: _inputDecoration(
                                'Altura (cm)',
                                Icons.height,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        maxLength: 8,
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _inputDecoration(
                              'Senha (até 8 caracteres) *',
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
                            return 'Crie uma senha';
                          }
                          if (value.length < 6) {
                            return 'Mínimo de 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBackground,
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
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _acceptedTerms,
                                activeColor: primaryGreen,
                                checkColor: Colors.black,
                                side: const BorderSide(
                                  color: Color(0xFF71717A),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _acceptedTerms = val ?? false;
                                    if (_acceptedTerms) _showTermsError = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                children: [
                                  const Text(
                                    'Li e concordo com os ',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showLegalModal(
                                      context,
                                      'Termos de Uso',
                                      '1. NATUREZA: Ferramenta autônoma.\n2. ISENÇÃO: Uso sob responsabilidade do utilizador.',
                                    ),
                                    child: const Text(
                                      'Termos de Uso',
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' e a ',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showLegalModal(
                                      context,
                                      'Política de Privacidade',
                                      '1. DADOS: Uso operacional.\n2. ARMAZENAMENTO: Local no dispositivo.',
                                    ),
                                    child: const Text(
                                      'Política de Privacidade',
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '.',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              return;
                            }

                            if (!_acceptedTerms) {
                              setState(() {
                                _showTermsError = true;
                              });
                              return;
                            }

                            try {
                              final studentUser = Student(
                                name: _nameController.text.trim(),
                                nickname:
                                    _usernameController.text.trim().isEmpty
                                    ? _nameController.text
                                          .trim()
                                          .toLowerCase()
                                          .replaceAll(' ', '')
                                    : _usernameController.text.trim(),
                                password: _passwordController.text.trim(),
                                weight:
                                    double.tryParse(_weightController.text) ??
                                    70.0,
                                objective: 'Geral',
                                startDate: DateTime.now(),
                                profileImageUrl: widget.initialProfileImageUrl,
                              );

                              // 1. Salva localmente no Sqflite[cite: 6]
                              await DatabaseHelper.instance.insertStudent(
                                studentUser,
                              );
                              StudentRepository.addStudent(studentUser);

                              // 2. Sincroniza e guarda os dados no Servidor do Firebase[cite: 6]
                              final firebaseService = FirebaseService();
                              await firebaseService.salvarAtletaNoFirebase(
                                studentUser,
                                widget.initialEmail ??
                                    _emailController.text.trim(),
                              );

                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeDashboardScreen(
                                    userData: studentUser.toMap(),
                                  ),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao criar conta: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.black,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 22,
                          ),
                          label: const Text(
                            'Criar minha conta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 8) text = text.substring(0, 8);
    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) formatted += '/';
      formatted += text[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class HeightInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 3) text = text.substring(0, 3);
    var formatted = text;
    if (text.length == 3) {
      formatted = '${text[0]},${text.substring(1)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
