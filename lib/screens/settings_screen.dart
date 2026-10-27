import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../models/student_model.dart';
import 'diagnosis.dart';
import 'workout_reminder_screen.dart';

class WeightLog {
  final double weight;
  final String date;
  final String time;

  WeightLog({required this.weight, required this.date, required this.time});
}

class SettingsScreen extends StatefulWidget {
  final Student? currentStudent;
  final ValueChanged<Student>? onStudentChanged;

  const SettingsScreen({super.key, this.currentStudent, this.onStudentChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color brandGreen = Color(0xFF22C55E);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  final List<Student> _testStudents = [
    Student(
      id: 1,
      name: 'Carlos Santos',
      nickname: 'Carlos',
      password: '1234',
      weight: 82.5,
      objective: 'Hipertrofia',
      waterGoalMl: 3000,
      waterConsumedToday: 1500,
      totalWorkouts: 12,
      isExpired: false,
      startDate: DateTime(2026, 1, 10),
    ),
    Student(
      id: 2,
      name: 'Ana Silva',
      nickname: 'Ana',
      password: '5678',
      weight: 63.0,
      objective: 'Emagrecimento',
      waterGoalMl: 2500,
      waterConsumedToday: 2000,
      totalWorkouts: 8,
      isExpired: false,
      startDate: DateTime(2026, 2, 1),
    ),
  ];

  late Student _selectedStudent;
  bool _isProfileExpanded = false;

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _objectiveController;
  late TextEditingController _avatarController;
  final TextEditingController _newWeightController = TextEditingController();

  bool _isSaved = false;
  final double _uploadProgress = 0.35;

  final Map<int, List<WeightLog>> _weightLogsMap = {
    1: [
      WeightLog(weight: 84.0, date: '2026-09-01', time: '08:00'),
      WeightLog(weight: 83.2, date: '2026-09-10', time: '08:15'),
      WeightLog(weight: 82.5, date: '2026-09-18', time: '09:30'),
    ],
    2: [
      WeightLog(weight: 64.5, date: '2026-09-05', time: '07:30'),
      WeightLog(weight: 63.0, date: '2026-09-15', time: '08:00'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.currentStudent ?? _testStudents.first;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _selectedStudent.name);
    _weightController = TextEditingController(
      text: _selectedStudent.weight.toString(),
    );
    _objectiveController = TextEditingController(
      text: _selectedStudent.objective,
    );
    _avatarController = TextEditingController(
      text: _selectedStudent.profileImageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _objectiveController.dispose();
    _avatarController.dispose();
    _newWeightController.dispose();
    super.dispose();
  }

  void _switchStudent(Student student) {
    setState(() {
      _selectedStudent = student;
      _initControllers();
      _newWeightController.clear();
    });
    if (widget.onStudentChanged != null) {
      widget.onStudentChanged!(_selectedStudent);
    }
  }

  String _getFallbackAvatar(String name, String objective) {
    final seed = name.replaceAll(' ', '_');
    if (objective.toLowerCase().contains('emagrecimento') ||
        objective.toLowerCase().contains('feminino') ||
        objective.toLowerCase().contains('ana')) {
      return 'https://api.dicebear.com/7.x/bottts/png?seed=${seed}_sticker_f';
    } else {
      return 'https://api.dicebear.com/7.x/avataaars/png?seed=${seed}_sticker_m';
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedStudent = _selectedStudent.copyWith(
          profileImageUrl: image.path,
        );
        _avatarController.text = image.path;
      });

      if (widget.onStudentChanged != null) {
        widget.onStudentChanged!(_selectedStudent);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil alterada com sucesso!'),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  ImageProvider _getAvatarImageProvider(String avatarPath) {
    if (avatarPath.isNotEmpty &&
        !avatarPath.startsWith('http') &&
        File(avatarPath).existsSync()) {
      return FileImage(File(avatarPath));
    } else if (avatarPath.startsWith('http')) {
      return NetworkImage(avatarPath);
    } else {
      return NetworkImage(
        _getFallbackAvatar(_selectedStudent.name, _selectedStudent.objective),
      );
    }
  }

  void _showExpandedProfileImage(String activeAvatar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Foto do Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: brandGreen, width: 3),
                  image: DecorationImage(
                    image: _getAvatarImageProvider(activeAvatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  _pickImageFromGallery();
                },
                icon: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.black,
                ),
                label: const Text(
                  'Trocar de Foto',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSaveWeight() {
    final text = _newWeightController.text.trim().replaceAll(',', '.');
    final w = double.tryParse(text);

    if (w == null || w < 20 || w > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peso inválido! Insira um valor entre 20 e 300 kg.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final studentId = _selectedStudent.id ?? 1;

    setState(() {
      _weightLogsMap[studentId] ??= [];
      _weightLogsMap[studentId]!.add(
        WeightLog(weight: w, date: today, time: time),
      );
      _newWeightController.clear();
      _isSaved = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSaved = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Peso registrado com sucesso!'),
        backgroundColor: brandGreen,
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: brandGreen),
            SizedBox(width: 8),
            Text(
              'Política de Privacidade',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Seus dados pessoais (peso, exames, treinos e metas) são protegidos em conformidade com a LGPD (Lei Geral de Proteção de Dados).\n\nNenhuma informação médica ou de desempenho é compartilhada com terceiros sem sua autorização expressa.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: brandGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String activeAvatar =
        (_selectedStudent.profileImageUrl != null &&
            _selectedStudent.profileImageUrl!.isNotEmpty)
        ? _selectedStudent.profileImageUrl!
        : _getFallbackAvatar(_selectedStudent.name, _selectedStudent.objective);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings_rounded, color: brandGreen, size: 26),
                      SizedBox(width: 10),
                      Text(
                        'Configurações',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<Student>(
                    color: cardBackground,
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      color: brandGreen,
                    ),
                    onSelected: _switchStudent,
                    itemBuilder: (context) => _testStudents.map((s) {
                      return PopupMenuItem<Student>(
                        value: s,
                        child: Text(
                          s.name,
                          style: TextStyle(
                            color: s.id == _selectedStudent.id
                                ? brandGreen
                                : Colors.white,
                            fontWeight: s.id == _selectedStudent.id
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildCardContainer(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: GestureDetector(
                        onTap: () => _showExpandedProfileImage(activeAvatar),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: brandGreen, width: 1.5),
                            image: DecorationImage(
                              image: _getAvatarImageProvider(activeAvatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      title: const Text(
                        'Meu Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _selectedStudent.name,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          _isProfileExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isProfileExpanded = !_isProfileExpanded;
                          });
                        },
                      ),
                    ),
                    if (_isProfileExpanded) ...[
                      const Divider(color: cardBorder),
                      const SizedBox(height: 8),
                      _buildTextField('Nome', _nameController),
                      const SizedBox(height: 10),
                      _buildTextField(
                        'Peso (kg)',
                        _weightController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField('Objetivo', _objectiveController),
                      const SizedBox(height: 10),
                      _buildTextField(
                        'Caminho da Foto (Local)',
                        _avatarController,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedStudent = _selectedStudent.copyWith(
                                name: _nameController.text,
                                weight:
                                    double.tryParse(_weightController.text) ??
                                    _selectedStudent.weight,
                                objective: _objectiveController.text,
                                profileImageUrl: _avatarController.text.trim(),
                              );
                            });

                            if (widget.onStudentChanged != null) {
                              widget.onStudentChanged!(_selectedStudent);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso!'),
                                backgroundColor: brandGreen,
                              ),
                            );
                          },
                          child: const Text(
                            'Salvar Alterações',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutReminderScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: _buildCardContainer(
                  child: Row(
                    children: const [
                      Icon(Icons.access_time_rounded, color: brandGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lembrete de Treino',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Configurar horários, alarme e dias da semana',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCardContainer(child: _buildWeightProgressSection()),
              const SizedBox(height: 16),

              // DADOS (Ícone alterado para verde brandGreen)
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.storage_rounded, color: brandGreen),
                        SizedBox(width: 10),
                        Text(
                          'Dados',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardBackground,
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Diagnosis360Screen(
                                isEditing: true,
                                existingData: {
                                  'objetivo': _selectedStudent.objective,
                                },
                                onSubmit: (updatedData) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Diagnóstico 360° atualizado com sucesso!',
                                      ),
                                      backgroundColor: brandGreen,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: brandGreen,
                        ),
                        label: const Text(
                          'Editar Diagnóstico 360°',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 18,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Exportar Protocolo',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ENVIO DE EXAMES (Barra de progresso alterada para verde brandGreen)
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.description_outlined, color: brandGreen),
                        SizedBox(width: 10),
                        Text(
                          'Envio de Exames',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload de PDF ou imagem com nome.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: const Color(0xFF1B261D),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          brandGreen,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // POLÍTICA DE PRIVACIDADE
              InkWell(
                onTap: _showPrivacyPolicyDialog,
                borderRadius: BorderRadius.circular(16),
                child: _buildCardContainer(
                  child: Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: brandGreen),
                      SizedBox(width: 12),
                      Text(
                        'Política de Privacidade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SAIR DA CONTA
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: _buildCardContainer(
                  child: Row(
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Center(
                child: Text(
                  'TREINOLIVRE Protocol v1.0 — Desenvolvido por C-Level IA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightProgressSection() {
    final studentId = _selectedStudent.id ?? 1;
    final logs = _weightLogsMap[studentId] ?? [];
    final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final latestLog = logs.isNotEmpty
        ? [...logs].reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
        : null;
    final currentWeight = latestLog?.weight ?? _selectedStudent.weight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.trending_up_rounded, color: brandGreen, size: 18),
                SizedBox(width: 8),
                Text(
                  'Evolução de Peso',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: brandGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: brandGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                _selectedStudent.objective,
                style: const TextStyle(
                  color: brandGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currentWeight.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'kg',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E0B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: _buildChartContent(sortedLogs),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _handleSaveWeight(),
                decoration: InputDecoration(
                  hintText: 'Ex: 82.5',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0A0E0B),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: brandGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  // Botão Salvar alterado para verde (brandGreen)
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _isSaved ? null : _handleSaveWeight,
                icon: Icon(
                  _isSaved ? Icons.check : Icons.add_rounded,
                  size: 18,
                  color: Colors.black,
                ),
                label: Text(
                  _isSaved ? 'Salvo!' : 'Salvar',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartContent(List<WeightLog> sortedLogs) {
    if (sortedLogs.isEmpty || sortedLogs.length == 1) {
      return const Center(
        child: Text(
          'Registre mais pesos para ver o gráfico.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedLogs[i].weight));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: brandGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0A0E0B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandGreen),
        ),
      ),
    );
  }
}
