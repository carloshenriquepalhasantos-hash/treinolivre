import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'dart:io';

import 'settings_screen.dart';
import 'diagnosis.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';
import 'workouts/workouts_screen.dart';
import 'diet_screen.dart';
import 'water_reminder_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeDashboardScreen({super.key, this.userData});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late Student _currentStudent;
  late PageController _pageController;

  DateTime _lastResetDate = DateTime.now();
  final List<double> _quickWaterAmounts = [300.0, 500.0, 1000.0];

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color brandGreen = Color(0xFF22C55E);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandOrange = Color(0xFFF59E0B);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  Map<String, dynamic>? _dadosDiagnosticoCache;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStudentData();
    _checkAndResetDailyWater();
    _pageController = PageController(initialPage: _currentIndex);
    _carregarDiagnosticoCache();
    _verificarDiagnosticoFirebase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndResetDailyWater();
      _carregarDiagnosticoCache();
    }
  }

  Future<void> _carregarDiagnosticoCache() async {
    if (widget.userData != null && widget.userData!.isNotEmpty) {
      setState(() {
        _dadosDiagnosticoCache = widget.userData;
      });
      return;
    }
    final User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('diagnosticos_360')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _dadosDiagnosticoCache = doc.data();
          });
        }
      } catch (e) {
        debugPrint('Erro ao carregar cache do diagnóstico: $e');
      }
    }
  }

  String _obterTreinoHojeTexto() {
    if (_dadosDiagnosticoCache == null ||
        !_dadosDiagnosticoCache!.containsKey('planoTreinoIA')) {
      return 'Descanso';
    }
    try {
      String planoIA = _dadosDiagnosticoCache!['planoTreinoIA'];
      String jsonLimpado = planoIA
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      int inicioJson = jsonLimpado.indexOf('{');
      int fimJson = jsonLimpado.lastIndexOf('}');
      if (inicioJson != -1 && fimJson != -1) {
        jsonLimpado = jsonLimpado.substring(inicioJson, fimJson + 1);
        Map<String, dynamic> mapaGeral = jsonDecode(jsonLimpado);
        var treinos = mapaGeral.containsKey('treinos')
            ? mapaGeral['treinos']
            : mapaGeral;

        if (treinos is Map) {
          String diaAtualStr = _obterDiaSemanaAtualFormatado();
          for (var entry in treinos.entries) {
            if (entry.key.toString().toLowerCase().contains(
              diaAtualStr.toLowerCase(),
            )) {
              var listaEx = entry.value;
              if (listaEx is List && listaEx.isNotEmpty) {
                return 'Ficha de ${entry.key} (${listaEx.length} ex)';
              }
            }
          }
        }
      }
    } catch (_) {}
    return 'Descanso';
  }

  String _obterProximaRefeicaoTexto() {
    if (_dadosDiagnosticoCache == null ||
        !_dadosDiagnosticoCache!.containsKey('planoTreinoIA')) {
      return _getFallbackMealHora();
    }
    try {
      String planoIA = _dadosDiagnosticoCache!['planoTreinoIA'];
      String jsonLimpado = planoIA
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      int inicioJson = jsonLimpado.indexOf('{');
      int fimJson = jsonLimpado.lastIndexOf('}');
      if (inicioJson != -1 && fimJson != -1) {
        jsonLimpado = jsonLimpado.substring(inicioJson, fimJson + 1);
        Map<String, dynamic> mapaGeral = jsonDecode(jsonLimpado);
        if (mapaGeral.containsKey('dieta') && mapaGeral['dieta'] is List) {
          List dietaList = mapaGeral['dieta'];
          if (dietaList.isNotEmpty) {
            // Seleciona com base no horário atual ou a primeira se cedo
            final now = DateTime.now();
            int horaAtualMin = now.hour * 60 + now.minute;

            for (var meal in dietaList) {
              String timeStr = meal['time'] ?? '08:00';
              var partes = timeStr.split(':');
              if (partes.length == 2) {
                int mealMin =
                    (int.tryParse(partes[0]) ?? 0) * 60 +
                    (int.tryParse(partes[1]) ?? 0);
                if (mealMin >= horaAtualMin) {
                  return '${meal['title']} (${meal['time']})';
                }
              }
            }
            // Se já passou de todas, retorna a primeira do dia seguinte (ou primeira da lista)
            return '${dietaList.first['title']} (${dietaList.first['time']})';
          }
        }
      }
    } catch (_) {}
    return _getFallbackMealHora();
  }

  String _getFallbackMealHora() {
    final hour = DateTime.now().hour;
    if (hour >= 20) return 'Jantar (21:00)';
    if (hour >= 18) return 'Lanche (18:00)';
    if (hour >= 15) return 'Pós-Treino (15:30)';
    if (hour >= 12) return 'Almoço (12:30)';
    return 'Café da Manhã (08:00)';
  }

  String _obterDiaSemanaAtualFormatado() {
    int weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Segunda';
    }
  }

  Future<void> _verificarDiagnosticoFirebase() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('diagnosticos_360').doc(user.uid);
      final docSnapshot = await docRef.get().timeout(
        const Duration(seconds: 5),
      );

      bool pendente = true;
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data['status'] == 'respondido') {
          pendente = false;
          setState(() {
            _dadosDiagnosticoCache = data;
          });
        }
      }

      if (pendente && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Diagnosis360Screen(
              isEditing: false,
              existingData: widget.userData,
              onSubmit: (completedData) async {
                await _firestore
                    .collection('diagnosticos_360')
                    .doc(user.uid)
                    .set({
                      ...completedData,
                      'status': 'respondido',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
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
      debugPrint('Erro ao verificar diagnóstico: $e');
    }
  }

  void _loadStudentData() {
    if (widget.userData != null) {
      _currentStudent = Student.fromMap(widget.userData!);
    } else {
      _currentStudent = StudentRepository.getStudents().first;
    }
  }

  void _checkAndResetDailyWater() {
    final now = DateTime.now();
    if (_lastResetDate.year != now.year ||
        _lastResetDate.month != now.month ||
        _lastResetDate.day != now.day) {
      setState(() {
        _currentStudent.waterConsumedToday = 0.0;
        _lastResetDate = now;
      });
    }
  }

  void _addWater(double amountMl) {
    _checkAndResetDailyWater();
    final double goal = _currentStudent.waterGoalMl;
    setState(() {
      final double total = _currentStudent.waterConsumedToday + amountMl;
      if (goal > 0 && total > goal) {
        _currentStudent.waterConsumedToday = goal;
      } else {
        _currentStudent.waterConsumedToday = total;
      }
    });
  }

  String _formatWater(double ml) {
    if (ml >= 1000) {
      double l = ml / 1000;
      return l % 1 == 0 ? '${l.toInt()}L' : '${l.toStringAsFixed(1)}L';
    }
    return '${ml.toInt()}ml';
  }

  String _getFallbackAvatar(String name, String objective) {
    final seed = name.replaceAll(' ', '_');
    if (objective.toLowerCase().contains('emagrecimento') ||
        objective.toLowerCase().contains('feminino')) {
      return 'https://api.dicebear.com/7.x/bottts/png?seed=${seed}_sticker_f';
    } else {
      return 'https://api.dicebear.com/7.x/avataaars/png?seed=${seed}_sticker_m';
    }
  }

  ImageProvider _getDashboardAvatarProvider() {
    final imgPath = _currentStudent.profileImageUrl;
    if (imgPath != null &&
        imgPath.isNotEmpty &&
        !imgPath.startsWith('http') &&
        File(imgPath).existsSync()) {
      return FileImage(File(imgPath));
    } else if (imgPath != null && imgPath.startsWith('http')) {
      return NetworkImage(imgPath);
    } else {
      return NetworkImage(
        _getFallbackAvatar(_currentStudent.name, _currentStudent.objective),
      );
    }
  }

  void _showEditWaterButtonsDialog() {
    final controller1 = TextEditingController(
      text: _quickWaterAmounts[0].toInt().toString(),
    );
    final controller2 = TextEditingController(
      text: _quickWaterAmounts[1].toInt().toString(),
    );
    final controller3 = TextEditingController(
      text: _quickWaterAmounts[2].toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Text(
          'Editar Botões Rápidos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defina os valores em ml para cada um dos 3 atalhos:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildAmountTextField(controller1, 'Atalho 1 (ml)'),
            const SizedBox(height: 10),
            _buildAmountTextField(controller2, 'Atalho 2 (ml)'),
            const SizedBox(height: 10),
            _buildAmountTextField(controller3, 'Atalho 3 (ml)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final val1 = double.tryParse(controller1.text);
              final val2 = double.tryParse(controller2.text);
              final val3 = double.tryParse(controller3.text);

              if (val1 != null &&
                  val1 > 0 &&
                  val2 != null &&
                  val2 > 0 &&
                  val3 != null &&
                  val3 > 0) {
                setState(() {
                  _quickWaterAmounts[0] = val1;
                  _quickWaterAmounts[1] = val2;
                  _quickWaterAmounts[2] = val3;
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1B261D),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brandGreen),
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomeContent(),
          WorkoutsScreen(userData: widget.userData ?? _dadosDiagnosticoCache),
          DietScreen(userData: widget.userData ?? _dadosDiagnosticoCache),
          SettingsScreen(
            currentStudent: _currentStudent,
            onStudentChanged: (updatedStudent) {
              setState(() {
                _currentStudent = updatedStudent;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBackground,
          border: const Border(top: BorderSide(color: cardBorder, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'INÍCIO'),
            _buildNavItem(1, Icons.fitness_center, 'TREINOS'),
            _buildNavItem(2, Icons.restaurant, 'DIETA'),
            _buildNavItem(3, Icons.settings_rounded, 'CONFIG'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final double goalMl = _currentStudent.waterGoalMl;
    final double consumedMl = _currentStudent.waterConsumedToday;
    final double progressPct = (goalMl > 0)
        ? (consumedMl / goalMl).clamp(0.0, 1.0)
        : 0.0;
    final int percentageText = (progressPct * 100).toInt();
    final bool isGoalAchieved = goalMl > 0 && consumedMl >= goalMl;

    final String treinoHojeTexto = _obterTreinoHojeTexto();
    final String proximaRefeicaoTexto = _obterProximaRefeicaoTexto();
    final String objetivoTexto =
        (_dadosDiagnosticoCache != null &&
            _dadosDiagnosticoCache!['objetivo'] != null)
        ? _dadosDiagnosticoCache!['objetivo']
        : _currentStudent.objective;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBackground,
                        border: Border.all(color: brandGreen, width: 2),
                        image: DecorationImage(
                          image: _getDashboardAvatarProvider(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'TREINO LIVRE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'EVOLUÇÃO',
                          style: TextStyle(
                            color: brandGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Olá,',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '${_currentStudent.name} 💪',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // HIDRATAÇÃO
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGoalAchieved ? brandGreen : cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGoalAchieved
                                ? Icons.verified
                                : Icons.water_drop_rounded,
                            color: isGoalAchieved ? brandGreen : brandBlue,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Hidratação',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$percentageText%',
                        style: TextStyle(
                          color: isGoalAchieved ? brandGreen : brandBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta: ${_formatWater(goalMl)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_formatWater(consumedMl)} / ${_formatWater(goalMl)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF1B261D),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isGoalAchieved ? brandGreen : brandBlue,
                      ),
                    ),
                  ),
                  if (isGoalAchieved) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: brandGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_events, color: brandGreen, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Parabéns! Meta de hidratação batida hoje! 🎉',
                              style: TextStyle(
                                color: brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adicionar rapidamente:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditWaterButtonsDialog,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: brandBlue,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Editar',
                              style: TextStyle(
                                color: brandBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildWaterButton(
                        '+${_formatWater(_quickWaterAmounts[0])}',
                        _quickWaterAmounts[0],
                      ),
                      const SizedBox(width: 8),
                      _buildWaterButton(
                        '+${_formatWater(_quickWaterAmounts[1])}',
                        _quickWaterAmounts[1],
                      ),
                      const SizedBox(width: 8),
                      _buildWaterButton(
                        '+${_formatWater(_quickWaterAmounts[2])}',
                        _quickWaterAmounts[2],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WaterReminderScreen(waterGoal: goalMl),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B261D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: brandBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: brandBlue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Cronograma e Notificações',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARDS DE TREINO E PRÓXIMA REFEIÇÃO (COM ÍCONES LARANJA/AMARELO E NAVEGAÇÃO)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _onNavItemTapped(1), // Vai para a aba de Treinos
                    child: _buildQuickCard(
                      icon: Icons.fitness_center_rounded,
                      iconColor: brandOrange,
                      title: 'Treino de Hoje',
                      subtitle: treinoHojeTexto,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onNavItemTapped(2), // Vai para a aba de Dieta
                    child: _buildQuickCard(
                      icon: Icons.restaurant_rounded,
                      iconColor: brandOrange,
                      title: 'Próxima Refeição',
                      subtitle: proximaRefeicaoTexto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ESTATÍSTICAS DO ALUNO (OBJETIVO PUXADO DO DIAGNOSIS)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: Colors.amber,
                    value: '${_currentStudent.weight.toInt()}',
                    label: 'Peso (kg)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.deepOrangeAccent,
                    value: '${_currentStudent.totalWorkouts}',
                    label: 'Treinos',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: brandGreen,
                    value: objetivoTexto,
                    label: 'Objetivo',
                    isTextValue: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(String label, double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _addWater(amount),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: brandBlue.withValues(alpha: 0.3)),
          backgroundColor: brandBlue.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: brandBlue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isTextValue ? 12 : 18,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 18,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
