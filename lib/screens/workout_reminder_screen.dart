import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutReminderScreen extends StatefulWidget {
  const WorkoutReminderScreen({super.key});

  @override
  State<WorkoutReminderScreen> createState() => _WorkoutReminderScreenState();
}

class _WorkoutReminderScreenState extends State<WorkoutReminderScreen> {
  // Cores da Nova Identidade Visual
  static const Color brandGreen = Color(0xFF22C55E);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  final TextEditingController _timeController = TextEditingController(
    text: '08:00',
  );

  // Dias da semana padronizados no Brasil
  final List<String> _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  final List<bool> _selectedDays = [true, true, true, true, true, false, false];

  bool _isAlarmActive = true;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  // Lógica ao ativar/desativar o alarme com vibração e aviso
  void _toggleAlarm(bool value) async {
    setState(() {
      _isAlarmActive = value;
    });

    if (value) {
      await HapticFeedback.vibrate();

      if (!mounted) return;

      final timeStr = _timeController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarme ativado! Tocará no celular e relógio às $timeStr.',
          ),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lembretes de treino desativados.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: brandGreen,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurar Lembrete de Treino',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: cardBorder, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com Ícone de Alarme e Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.alarm_rounded,
                              color: brandGreen,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Alarme Inteligente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isAlarmActive,
                          activeThumbColor: brandGreen,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: cardBorder,
                          onChanged: _toggleAlarm,
                        ),
                      ],
                    ),
                    const Divider(color: cardBorder, height: 24),

                    // Inserção de Horário (Digitar)
                    const Text(
                      'Horário do Alarme (Digite HH:MM)',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _timeController,
                      keyboardType: TextInputType.datetime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: darkBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: const Icon(
                          Icons.access_time_filled_rounded,
                          color: brandGreen,
                        ),
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
                    const SizedBox(height: 20),

                    // Dias da Semana (Segunda a Domingo)
                    const Text(
                      'Dias da Semana',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final isSelected = _selectedDays[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDays[index] = !_selectedDays[index];
                            });
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            width: 38,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? brandGreen : darkBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? brandGreen : cardBorder,
                              ),
                            ),
                            child: Text(
                              _days[index],
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Configurações de lembrete salvas com sucesso!',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: brandGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, color: Colors.black),
                  label: const Text(
                    'Salvar Configurações',
                    style: TextStyle(
                      color: Colors.black,
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
    );
  }
}
