import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Instância global do plugin de notificações
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class WaterReminderScreen extends StatefulWidget {
  final double waterGoal;

  const WaterReminderScreen({super.key, required this.waterGoal});

  @override
  State<WaterReminderScreen> createState() => _WaterReminderScreenState();
}

class _WaterReminderScreenState extends State<WaterReminderScreen> {
  // Cores com tema inteiramente Azul para a Hidratação
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandLightBlue = Color(0xFF60A5FA);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  bool _notificationsEnabled = false;
  int _numberOfIntervals = 4;
  late double _currentWaterGoal;
  late List<Map<String, TextEditingController>> _scheduleControllers;

  @override
  void initState() {
    super.initState();
    _currentWaterGoal = widget.waterGoal;
    _initNotifications();
    _generateSchedule();
  }

  @override
  void dispose() {
    for (var item in _scheduleControllers) {
      item['time']?.dispose();
    }
    super.dispose();
  }

  // Inicializa as configurações de notificações e fuso horário com o ícone do app
  void _initNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Agenda as notificações utilizando o ícone do app (@mipmap/ic_launcher)
  Future<void> _scheduleAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    if (!_notificationsEnabled) return;

    for (int i = 0; i < _scheduleControllers.length; i++) {
      final item = _scheduleControllers[i];
      final timeParts = item['time']!.text.split(':');
      if (timeParts.length != 2) continue;

      final int hour = int.tryParse(timeParts[0]) ?? 8;
      final int minute = int.tryParse(timeParts[1]) ?? 0;
      final String amount = item['amount']!.text;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        if (scheduledDate.year == now.year &&
            scheduledDate.month == now.month &&
            scheduledDate.day == now.day &&
            now.difference(scheduledDate).inMinutes < 2) {
          scheduledDate = now.add(const Duration(seconds: 5));
        } else {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'water_reminder_channel_v7',
            'Lembretes de Hidratação',
            channelDescription:
                'Notificações com som e vibração para beber água',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
            color: brandBlue,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: i,
        title: 'Hora de se hidratar! 💧',
        body: 'Beba $amount de água para manter sua meta em dia.',
        scheduledDate: scheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  void _generateSchedule() {
    List<Map<String, TextEditingController>> newSchedule = [];
    double goal = _currentWaterGoal;
    int count = _numberOfIntervals;
    if (count < 1) count = 1;

    double rawPortion = goal / count;
    double startHour = 7.0;
    double endHour = 21.0;
    double step = (count > 1) ? (endHour - startHour) / (count - 1) : 0;

    double accumulatedWater = 0;

    for (int i = 0; i < count; i++) {
      double currentHourDecimal = startHour + (i * step);
      int hour = currentHourDecimal.floor();
      int minute = ((currentHourDecimal - hour) * 60).round();

      minute = (minute / 5).round() * 5;
      if (minute >= 60) {
        hour += 1;
        minute = 0;
      }

      double portion;
      if (i == count - 1) {
        portion = goal - accumulatedWater;
      } else {
        portion = (rawPortion / 50).round() * 50;
        if (portion <= 0) portion = 50;
        accumulatedWater += portion;

        if (accumulatedWater >= goal) {
          portion = goal - (accumulatedWater - portion);
          accumulatedWater = goal;
        }
      }

      final timeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      final amountStr = '${portion.toInt()} ml';

      newSchedule.add({
        'time': TextEditingController(text: timeStr),
        'amount': TextEditingController(text: amountStr),
      });
    }

    setState(() {
      _scheduleControllers = newSchedule;
    });

    if (_notificationsEnabled) {
      _scheduleAllNotifications();
    }
  }

  // Salva a nova meta no Firebase e atualiza o estado localmente
  Future<void> _salvarMetaAtualizada(double novaMeta) async {
    setState(() {
      _currentWaterGoal = novaMeta;
      _generateSchedule();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('diagnosticos_360')
            .doc(user.uid)
            .update({
              'waterGoalMl': novaMeta,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('Erro ao salvar meta de água no Firebase: $e');
    }
  }

  // Diálogo para editar a meta manualmente
  void _showEditGoalDialog() {
    TextEditingController controller = TextEditingController(
      text: _currentWaterGoal.toInt().toString(),
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
          'Editar Meta Diária',
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
              'Digite sua nova meta diária em mililitros (ml):',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: darkBackground,
                labelText: 'Ex: 3000',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandBlue),
                ),
              ),
            ),
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
              double? val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                _salvarMetaAtualizada(val);
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

  // Calculadora de Água baseada em Peso e Altura com Mensagem Informativa
  void _showCalculatorDialog() {
    final TextEditingController pesoController = TextEditingController();
    final TextEditingController alturaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.calculate_rounded, color: brandLightBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Calcular Água Ideal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira seus dados para calcular a quantidade ideal de água:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: darkBackground,
                labelText: 'Peso (kg) - Ex: 75',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandBlue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: darkBackground,
                labelText: 'Altura (cm) - Ex: 175',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandBlue),
                ),
              ),
            ),
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
              double? peso = double.tryParse(pesoController.text);

              if (peso != null && peso > 0) {
                double calculatedGoal = peso * 35.0;

                _salvarMetaAtualizada(calculatedGoal);
                Navigator.pop(context);

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: cardBorder),
                    ),
                    title: const Text(
                      'Quantidade Ideal Calculada! 💧',
                      style: TextStyle(
                        color: brandLightBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Com base no seu peso (${peso.toInt()} kg), você precisa beber aproximadamente ${calculatedGoal.toInt()} ml de água por dia para se manter hidratado!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Entendido',
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
            },
            child: const Text(
              'Calcular',
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

  void _showIntervalDialog() {
    TextEditingController controller = TextEditingController(
      text: _numberOfIntervals.toString(),
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
          'Quantidade de Horários',
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
              'Quantas vezes você quer fracionar sua água hoje?',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: darkBackground,
                labelText: 'Número de vezes (ex: 4, 6, 8)',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandBlue),
                ),
              ),
            ),
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
              int? val = int.tryParse(controller.text);
              if (val != null && val > 0 && val <= 24) {
                setState(() {
                  _numberOfIntervals = val;
                  _generateSchedule();
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Aplicar',
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

  void _toggleNotifications(bool value) async {
    await HapticFeedback.heavyImpact();

    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await flutterLocalNotificationsPlugin.show(
        id: 999,
        title: 'Notificação Ativada! 💧',
        body: 'Se você ouviu o som, as notificações estão funcionando corretamente.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminder_channel_v7',
            'Lembretes de Hidratação',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );

      await _scheduleAllNotifications();
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRA SUPERIOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: brandLightBlue,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Voltar',
                          style: TextStyle(
                            color: brandLightBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _toggleNotifications(!_notificationsEnabled),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            _notificationsEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            color: _notificationsEnabled
                                ? brandLightBlue
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeThumbColor: brandLightBlue,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: cardBorder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TÍTULO E META DE ÁGUA COM LÁPIS AO LADO DA META E BOTÃO DE CALCULAR ABAIXO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cronograma de Hidratação',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // BOTÃO DE CALCULAR ABAIXO DO TÍTULO
                  GestureDetector(
                    onTap: _showCalculatorDialog,
                    child: Row(
                      children: const [
                        Icon(
                          Icons.calculate_rounded,
                          color: brandLightBlue,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Calcular quantidade de água',
                          style: TextStyle(
                            color: brandLightBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // META DIÁRIA COM O LÁPIS DE EDIÇÃO DIRETAMENTE AO LADO
                  Row(
                    children: [
                      Text(
                        'Meta diária: ${_currentWaterGoal.toInt()} ml',
                        style: const TextStyle(
                          color: brandLightBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showEditGoalDialog,
                        child: const Icon(
                          Icons.edit_rounded,
                          color: brandLightBlue,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // BOTÃO DE INTERVALOS
                  GestureDetector(
                    onTap: _showIntervalDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                color: brandBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Fracionar em: $_numberOfIntervals vezes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Text(
                                'Alterar',
                                style: TextStyle(
                                  color: brandLightBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LISTA DE HORÁRIOS COM DIGITAÇÃO DIRETA
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _scheduleControllers.length,
                itemBuilder: (context, index) {
                  final item = _scheduleControllers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          color: brandBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: item['time'],
                            keyboardType: TextInputType.datetime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              if (_notificationsEnabled) {
                                _scheduleAllNotifications();
                              }
                            },
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 85,
                          child: TextField(
                            controller: item['amount'],
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              color: brandLightBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.water_drop_rounded,
                          color: brandBlue,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
