import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/student_model.dart';
import 'home_dashboard_screen.dart';

class Diagnosis360Screen extends StatefulWidget {
  final bool isEditing;
  final bool isHistoryMode;
  final Map<String, dynamic>? existingData;
  final Student? student;
  final Function(Map<String, dynamic> data)? onSubmit;

  const Diagnosis360Screen({
    super.key,
    this.isEditing = false,
    this.isHistoryMode = false,
    this.existingData,
    this.student,
    this.onSubmit,
  });

  @override
  State<Diagnosis360Screen> createState() => _Diagnosis360ScreenState();
}

class _Diagnosis360ScreenState extends State<Diagnosis360Screen> {
  static const Color brandGreen = Color(0xFF22C55E);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _listaModelosIA = [
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-flash-latest',
  ];

  String _objetivoSelecionado = 'Hipertrofia';
  String _nivelSelecionado = 'Intermediário';
  String _localTreino = 'Academia';
  int _diasTreinoPorSemana = 4;

  final Map<String, bool> _diasSelecionados = {
    'Segunda': true,
    'Terça': true,
    'Quarta': false,
    'Quinta': true,
    'Sexta': true,
    'Sábado': false,
    'Domingo': false,
  };

  String _duracaoTreino = '60 min';
  String _estiloDieta = 'Onívoro (Com de tudo)';
  final TextEditingController _lesoesController = TextEditingController(
    text: 'Nenhuma',
  );
  final TextEditingController _restricoesController = TextEditingController(
    text: 'Nenhuma',
  );

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _objetivoSelecionado = widget.existingData!['objetivo'] ?? 'Hipertrofia';
      _nivelSelecionado = widget.existingData!['nivel'] ?? 'Intermediário';
      _localTreino = widget.existingData!['localTreino'] ?? 'Academia';
      _diasTreinoPorSemana = widget.existingData!['diasTreino'] ?? 4;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lesoesController.dispose();
    _restricoesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: brandGreen)),
    );

    List<String> diasAtivos = _diasSelecionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final Map<String, dynamic> answers = {
      'objetivo': _objetivoSelecionado,
      'nivel': _nivelSelecionado,
      'localTreino': _localTreino,
      'diasTreino': _diasTreinoPorSemana,
      'diasDaSemana': diasAtivos,
      'duracaoTreino': _duracaoTreino,
      'estiloDieta': _estiloDieta,
      'lesoes': _lesoesController.text,
      'restricoes': _restricoesController.text,
      'status': 'respondido',
      'completedAt': DateTime.now().toIso8601String(),
    };

    final prompt =
        '''
      Atue como um Personal Trainer de elite e Nutricionista esportivo. 
      Crie um programa completo para o aluno com base nestes dados:
      - Objetivo: $_objetivoSelecionado
      - Nível: $_nivelSelecionado
      - Local: $_localTreino
      - Dias de treino ativos: ${diasAtivos.join(', ')}
      - Lesões: ${_lesoesController.text}
      - Dieta: $_estiloDieta

      Responda ESTRITAMENTE em formato JSON válido contendo exatamente estas chaves:
      1. "treinos": Um objeto onde cada chave é um dia ativo (${diasAtivos.join(', ')}) e o valor é uma lista de 4 a 5 exercícios. Cada exercício deve conter obrigatoriamente as chaves: "nome", "series" (ex: "4"), "reps" (ex: "10-12"), "carga" (ex: 15.0), "descanso" (ex: 60).
      2. "dieta": Uma lista contendo objetos de refeições detalhadas. Cada refeição deve ter obrigatoriamente as chaves: "time" (ex: "08:00"), "title" (ex: "CAFÉ DA MANHÃ"), "items" (lista de strings com os alimentos), "substitutions" (lista de strings com opções de substituição). Crie pelo menos 4 refeições (Café da Manhã, Almoço, Lanche da Tarde e Jantar).

      Não inclua nenhum texto formatado em markdown ou fora do JSON. Apenas o objeto JSON puro.
    ''';

    String planoGeradoPelaIA = '';
    for (String modeloNome in _listaModelosIA) {
      try {
        final model = GenerativeModel(model: modeloNome, apiKey: '');
        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          planoGeradoPelaIA = response.text!;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (planoGeradoPelaIA.isEmpty) {
      planoGeradoPelaIA = '{}';
    }

    final Map<String, dynamic> dadosCompletos = {
      ...answers,
      'planoTreinoIA': planoGeradoPelaIA,
    };

    if (widget.onSubmit != null) {
      widget.onSubmit!(dadosCompletos);
    }

    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('diagnosticos_360')
            .doc(user.uid)
            .set(dadosCompletos);
      } catch (e) {
        debugPrint('Erro Firestore: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeDashboardScreen(userData: dadosCompletos),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showBackButton = widget.isEditing || widget.isHistoryMode;
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: brandGreen,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Configuração Inteligente (360°)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: cardBorder,
            color: brandGreen,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1ObjetivoENivel(),
                _buildStep2RotinaEFracionamento(),
                _buildStep3DietaESaude(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: cardBorder),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _currentStep == _totalSteps - 1
                        ? 'Gerar Treino & Dieta 🚀'
                        : 'Próximo',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStep1ObjetivoENivel() {
    return _buildStepContainer(
      title: '🎯 Qual é o seu foco principal?',
      subtitle: 'Defina seu objetivo e onde pretende treinar.',
      children: [
        const Text(
          'Objetivo',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildGridSelector(
          items: ['Hipertrofia', 'Emagrecimento', 'Definição', 'Resistência'],
          selected: _objetivoSelecionado,
          onSelect: (val) => setState(() => _objetivoSelecionado = val),
          icons: [
            Icons.fitness_center,
            Icons.local_fire_department,
            Icons.bolt,
            Icons.directions_run,
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Nível de Experiência',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildGridSelector(
          items: ['Iniciante', 'Intermediário', 'Avançado'],
          selected: _nivelSelecionado,
          onSelect: (val) => setState(() => _nivelSelecionado = val),
          icons: [Icons.star_border, Icons.star_half, Icons.star],
        ),
        const SizedBox(height: 20),
        const Text(
          'Local de Treino',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildGridSelector(
          items: ['Academia', 'Casa'],
          selected: _localTreino,
          onSelect: (val) => setState(() => _localTreino = val),
          icons: [Icons.apartment, Icons.home],
        ),
      ],
    );
  }

  Widget _buildStep2RotinaEFracionamento() {
    return _buildStepContainer(
      title: '📅 Como será sua rotina?',
      subtitle: 'Selecione os dias da semana e a duração das sessões.',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dias de Treino por Semana:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: brandGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_diasTreinoPorSemana dias',
                style: const TextStyle(
                  color: brandGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _diasTreinoPorSemana.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          activeColor: brandGreen,
          inactiveColor: cardBorder,
          onChanged: (val) =>
              setState(() => _diasTreinoPorSemana = val.toInt()),
        ),
        const SizedBox(height: 10),
        const Text(
          'Marque os dias que irá treinar:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _diasSelecionados.keys.map((dia) {
            bool ativo = _diasSelecionados[dia]!;
            return FilterChip(
              label: Text(dia),
              selected: ativo,
              selectedColor: brandGreen,
              checkmarkColor: Colors.black,
              backgroundColor: cardBackground,
              labelStyle: TextStyle(
                color: ativo ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: ativo ? brandGreen : cardBorder),
              ),
              onSelected: (bool value) {
                setState(() {
                  _diasSelecionados[dia] = value;
                  _diasTreinoPorSemana = _diasSelecionados.values
                      .where((v) => v)
                      .length;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tempo disponível por sessão',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildGridSelector(
          items: ['30 min', '45 min', '60 min', '90 min'],
          selected: _duracaoTreino,
          onSelect: (val) => setState(() => _duracaoTreino = val),
          icons: [
            Icons.timer_3,
            Icons.timer_outlined,
            Icons.timer,
            Icons.more_time,
          ],
        ),
      ],
    );
  }

  Widget _buildStep3DietaESaude() {
    return _buildStepContainer(
      title: '🥗 Escolha o estilo da sua Dieta',
      subtitle: 'Selecione o plano nutricional ideal para seu corpo.',
      children: [
        _buildDietCard(
          title: 'Onívoro (Flexível)',
          desc: 'Com de tudo de forma equilibrada (proteínas, carboidratos e gorduras).',
          icon: Icons.restaurant_menu,
          value: 'Onívoro (Com de tudo)',
        ),
        const SizedBox(height: 10),
        _buildDietCard(
          title: 'Low Carb',
          desc: 'Foco na redução de carboidratos refinados e controle de insulina.',
          icon: Icons.eco,
          value: 'Low Carb',
        ),
        const SizedBox(height: 10),
        _buildDietCard(
          title: 'Vegetariano',
          desc: 'Rico em vegetais, grãos e laticínios, sem carnes.',
          icon: Icons.spa,
          value: 'Vegetariano',
        ),
        const SizedBox(height: 10),
        _buildDietCard(
          title: 'Ketogênica (Keto)',
          desc:
              'Altamente restritiva em carboidratos com foco em gorduras boas.',
          icon: Icons.local_fire_department,
          value: 'Ketogênica',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          'Possui lesões ou dores articulares?',
          _lesoesController,
          'Ex: Nenhuma ou dor no ombro direito',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Restrições ou alergias alimentares?',
          _restricoesController,
          'Ex: Intolerância à lactose, nenhuma',
        ),
      ],
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildGridSelector({
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
    required List<IconData> icons,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        String item = items[index];
        bool isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? brandGreen.withValues(alpha: 0.2)
                  : cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? brandGreen : cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icons[index],
                  color: isSelected ? brandGreen : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDietCard({
    required String title,
    required String desc,
    required IconData icon,
    required String value,
  }) {
    bool isSelected = _estiloDieta == value;
    return GestureDetector(
      onTap: () => setState(() => _estiloDieta = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? brandGreen.withValues(alpha: 0.15)
              : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandGreen : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? brandGreen : darkBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : brandGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: brandGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            filled: true,
            fillColor: cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: brandGreen),
            ),
          ),
        ),
      ],
    );
  }
}
