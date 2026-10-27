import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/workout_model.dart';
import '../../widgets/exercise_card.dart';
import '../../database/database_helper.dart';

class WorkoutsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const WorkoutsScreen({super.key, this.userData});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _diaSelecionado = 'Segunda';
  final List<String> _diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  Map<String, List<ExerciseModel>> _fichasPorDia = {};
  Map<String, dynamic>? _dadosDiagnostico;
  var _isLoading = true;

  static const Color brandGreen = Color(0xFF22C55E);
  static const Color brandOrange = Color(0xFFF59E0B);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  final List<String> _listaModelosIA = [
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-flash-latest',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarTreinos();
  }

  Future<void> _inicializarTreinos() async {
    setState(() => _isLoading = true);

    await _carregarDadosDiagnostico();
    bool veioNovoDiagnostico =
        widget.userData != null && widget.userData!.isNotEmpty;

    if (!veioNovoDiagnostico) {
      bool carregouDoSqlite = await _carregarDoSqlite();
      if (carregouDoSqlite && _fichasPorDia.isNotEmpty) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (_dadosDiagnostico != null && _dadosDiagnostico!.isNotEmpty) {
      String planoIA = _dadosDiagnostico!['planoTreinoIA'] ?? '';

      if (planoIA.isEmpty) {
        planoIA = await _gerarTreinoCompletoComIA(_dadosDiagnostico!);
      }

      Map<String, List<ExerciseModel>> fichas =
          _parsearTreinoCompletoInteligente(planoIA);

      if (fichas.isNotEmpty) {
        setState(() {
          _fichasPorDia = fichas;
          if (!_fichasPorDia.containsKey(_diaSelecionado)) {
            _diaSelecionado = _fichasPorDia.keys.first;
          }
        });
        await _salvarNoSqlite(fichas);
      } else {
        _carregarTreinoPadrao();
      }
    } else {
      _carregarTreinoPadrao();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _carregarDadosDiagnostico() async {
    Map<String, dynamic>? data = widget.userData;
    if (data == null || data.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('diagnosticos_360')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            data = doc.data();
          }
        } catch (e) {
          debugPrint('Erro ao buscar Diagnóstico: $e');
        }
      }
    }
    _dadosDiagnostico = data;
  }

  Future<bool> _carregarDoSqlite() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final treinosSalvos = await dbHelper.getWorkoutsByStudent(1);
      if (treinosSalvos.isNotEmpty) {
        Map<String, List<ExerciseModel>> fichasLocais = {};
        for (var treino in treinosSalvos) {
          if (treino.exercises.isNotEmpty) {
            fichasLocais[treino.dayOfWeek] = treino.exercises;
          }
        }
        if (fichasLocais.isNotEmpty) {
          setState(() {
            _fichasPorDia = fichasLocais;
            if (!_fichasPorDia.containsKey(_diaSelecionado)) {
              _diaSelecionado = _fichasPorDia.keys.first;
            }
          });
          return true;
        }
      }
    } catch (e) {
      debugPrint('Erro ao ler do SQLite: $e');
    }
    return false;
  }

  Future<void> _salvarNoSqlite(Map<String, List<ExerciseModel>> fichas) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('workouts');

      final dbHelper = DatabaseHelper.instance;
      for (var entry in fichas.entries) {
        final protocolo = WorkoutProtocol(
          studentId: 1,
          name: 'Ficha de ${entry.key}',
          dayOfWeek: entry.key,
          exercises: entry.value,
        );
        await dbHelper.insertWorkout(protocolo);
      }
      debugPrint('Treinos salvos com sucesso no SQLite!');
    } catch (e) {
      debugPrint('Erro ao salvar no SQLite: $e');
    }
  }

  Future<void> _pesquisarEAbrirVideoYoutube(String nomeExercicio) async {
    final query = Uri.encodeComponent(
      '$nomeExercicio como fazer execução correta',
    );
    final url = Uri.parse(
      'https://www.youtube.com/results?search_query=$query',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir YouTube: $e');
    }
  }

  Future<String> _gerarTreinoCompletoComIA(Map<String, dynamic> data) async {
    final prompt = '''
      Crie um treino em formato ESTRITAMENTE JSON contendo uma chave "treinos" onde os dias ("Segunda", "Terça", etc.) mapeiam para listas de exercícios ("nome", "series", "reps", "carga", "descanso").
    ''';

    for (String modelo in _listaModelosIA) {
      try {
        final generativeModel = GenerativeModel(model: modelo, apiKey: '');
        final response = await generativeModel.generateContent([
          Content.text(prompt),
        ]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (_) {
        continue;
      }
    }
    return '';
  }

  void _mostrarDialogoGerarOutroTreino() {
    final Map<String, bool> membrosSelecionados = {
      'Peito': false,
      'Costas': false,
      'Pernas': false,
      'Ombros': false,
      'Bíceps': false,
      'Tríceps': false,
      'Abdômen': false,
      'Glúteos': false,
    };

    String localTreinoSelecionado = 'Academia';
    final List<String> locaisDisponiveis = [
      'Academia',
      'Casa',
      'Calistenia',
      'Crossfit',
    ];

    final TextEditingController seriesController = TextEditingController(
      text: '4',
    );
    final TextEditingController detalhesController = TextEditingController();
    bool mesclarTreino = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: cardBorder),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.settings_suggest_rounded,
                    color: brandOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gerar Treino: $_diaSelecionado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modalidade / Local:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: locaisDisponiveis.map((local) {
                          bool isSelected = localTreinoSelecionado == local;
                          IconData iconeLocal = local == 'Academia'
                              ? Icons.apartment
                              : local == 'Casa'
                              ? Icons.home
                              : local == 'Calistenia'
                              ? Icons.accessibility_new
                              : Icons.local_fire_department; // Ícone para Crossfit

                          return GestureDetector(
                            onTap: () => setDialogState(
                              () => localTreinoSelecionado = local,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? brandGreen : darkBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? brandGreen : cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconeLocal,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white70,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    local,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selecione os membros a treinar:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...membrosSelecionados.keys.map((membro) {
                        return CheckboxListTile(
                          title: Text(
                            membro,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          value: membrosSelecionados[membro],
                          activeColor: brandGreen,
                          checkColor: Colors.black,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? val) {
                            setDialogState(() {
                              membrosSelecionados[membro] = val ?? false;
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'Quantidade de Séries por Exercício:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: seriesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ex: 4',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: darkBackground,
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
                      const SizedBox(height: 12),
                      const Text(
                        'Detalhes / WOD / Observações (Opcional):',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detalhesController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ex: WOD com alta intensidade, AMRAP...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: darkBackground,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: mesclarTreino,
                            activeColor: brandGreen,
                            checkColor: Colors.black,
                            onChanged: (val) {
                              setDialogState(
                                () => mesclarTreino = val ?? false,
                              );
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Mesclar com os exercícios atuais do dia',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
                  onPressed: () {
                    List<String> membrosEscolhidos = membrosSelecionados.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();

                    if (membrosEscolhidos.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selecione pelo menos um membro corporal!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    String qtdSeries = seriesController.text.trim();
                    if (qtdSeries.isEmpty) qtdSeries = '4';

                    Navigator.pop(context);
                    _gerarTreinoPersonalizadoComIA(
                      localTreinoSelecionado,
                      membrosEscolhidos.join(', '),
                      qtdSeries,
                      detalhesController.text,
                      mesclarTreino,
                    );
                  },
                  child: const Text(
                    'Gerar Treino',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _gerarTreinoPersonalizadoComIA(
    String localTreino,
    String focoMembros,
    String qtdSeries,
    String detalhes,
    bool mesclar,
  ) async {
    setState(() => _isLoading = true);

    final prompt =
        '''
      Atue como um Coach de elite especialista em $localTreino. Crie um treino customizado para o dia "$_diaSelecionado".
      - Modalidade/Local: $localTreino
      - Membros focados: $focoMembros
      - Quantidade de séries exigida para cada exercício: $qtdSeries
      - Detalhes adicionais do aluno/WOD: $detalhes

      Responda ESTRITAMENTE em formato JSON válido contendo uma lista de 4 a 6 exercícios adaptados especificamente para a modalidade "$localTreino" focados nestes membros com exatamente $qtdSeries séries cada. Cada exercício deve conter as chaves: "nome", "series", "reps", "carga", "descanso".
      Exemplo de formato:
      [
        {"nome": "Burpees", "series": "$qtdSeries", "reps": "15", "carga": 0.0, "descanso": 45}
      ]
      Retorne apenas o JSON puro.
    ''';

    List<ExerciseModel> novosExercicios = [];

    for (String modelo in _listaModelosIA) {
      try {
        final generativeModel = GenerativeModel(model: modelo, apiKey: '');
        final response = await generativeModel.generateContent([
          Content.text(prompt),
        ]);
        if (response.text != null && response.text!.isNotEmpty) {
          String jsonText = response.text!
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          int start = jsonText.indexOf('[');
          int end = jsonText.lastIndexOf(']');
          if (start != -1 && end != -1) {
            jsonText = jsonText.substring(start, end + 1);
            List<dynamic> parsedList = jsonDecode(jsonText);

            novosExercicios = parsedList.map((item) {
              return ExerciseModel(
                name: _sanitizarNomeExercicio(item['nome']?.toString() ?? ''),
                sets: item['series']?.toString() ?? qtdSeries,
                reps: item['reps']?.toString() ?? '10-12',
                loadKg: (item['carga'] as num?)?.toDouble() ?? 0.0,
                restSeconds: (item['descanso'] as num?)?.toInt() ?? 60,
              );
            }).toList();

            if (novosExercicios.isNotEmpty) break;
          }
        }
      } catch (_) {}
    }

    if (novosExercicios.isNotEmpty) {
      setState(() {
        if (mesclar && _fichasPorDia.containsKey(_diaSelecionado)) {
          _fichasPorDia[_diaSelecionado]!.addAll(novosExercicios);
        } else {
          _fichasPorDia[_diaSelecionado] = novosExercicios;
        }
      });

      await _salvarNoSqlite(_fichasPorDia);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Map<String, dynamic> treinosMap = {};
          _fichasPorDia.forEach((dia, exercicios) {
            treinosMap[dia] = exercicios
                .map(
                  (ex) => {
                    'nome': ex.name,
                    'series': ex.sets,
                    'reps': ex.reps,
                    'carga': ex.loadKg,
                    'descanso': ex.restSeconds,
                  },
                )
                .toList();
          });

          if (_dadosDiagnostico != null) {
            Map<String, dynamic> planoAtualJson = {};
            try {
              String planoIAStr = _dadosDiagnostico!['planoTreinoIA'] ?? '{}';
              String limpo = planoIAStr
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              int ini = limpo.indexOf('{');
              int fim = limpo.lastIndexOf('}');
              if (ini != -1 && fim != -1) {
                planoAtualJson = jsonDecode(limpo.substring(ini, fim + 1));
              }
            } catch (_) {}

            planoAtualJson['treinos'] = treinosMap;

            String novoPlanoJsonStr = jsonEncode(planoAtualJson);
            _dadosDiagnostico!['planoTreinoIA'] = novoPlanoJsonStr;

            await FirebaseFirestore.instance
                .collection('diagnosticos_360')
                .doc(user.uid)
                .update({
                  'planoTreinoIA': novoPlanoJsonStr,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        }
      } catch (e) {
        debugPrint('Erro ao sincronizar treino com Firebase: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino gerado e salvo com sucesso! 🚀'),
            backgroundColor: brandGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível gerar o treino. Tente novamente.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Map<String, List<ExerciseModel>> _parsearTreinoCompletoInteligente(
    String entrada,
  ) {
    Map<String, List<ExerciseModel>> resultado = {};

    try {
      String jsonLimpado = entrada
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      int inicioJson = jsonLimpado.indexOf('{');
      int fimJson = jsonLimpado.lastIndexOf('}');

      if (inicioJson != -1 && fimJson != -1) {
        jsonLimpado = jsonLimpado.substring(inicioJson, fimJson + 1);
        Map<String, dynamic> mapaGeral = jsonDecode(jsonLimpado);

        var mapaJson = mapaGeral.containsKey('treinos')
            ? mapaGeral['treinos']
            : mapaGeral;

        if (mapaJson is Map) {
          mapaJson.forEach((dia, listaExercicios) {
            if (listaExercicios is List) {
              List<ExerciseModel> exercicios = [];
              for (var item in listaExercicios) {
                if (item is Map) {
                  String nome = _sanitizarNomeExercicio(
                    item['nome']?.toString() ?? '',
                  );
                  if (nome.isNotEmpty) {
                    exercicios.add(
                      ExerciseModel(
                        name: nome,
                        sets: item['series']?.toString() ?? '4',
                        reps: item['reps']?.toString() ?? '10-12',
                        loadKg: (item['carga'] as num?)?.toDouble() ?? 15.0,
                        restSeconds: (item['descanso'] as num?)?.toInt() ?? 60,
                      ),
                    );
                  }
                }
              }
              if (exercicios.isNotEmpty) {
                resultado[_normalizarNomeDia(dia)] = exercicios;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao parsear JSON da IA: $e');
    }

    return resultado;
  }

  String _sanitizarNomeExercicio(String texto) {
    return texto.replaceAll('**', '').replaceAll('*', '').trim();
  }

  String _normalizarNomeDia(String diaRaw) {
    String d = diaRaw.toLowerCase();
    for (var diaOriginal in _diasSemana) {
      if (d.contains(diaOriginal.toLowerCase())) return diaOriginal;
    }
    return diaRaw;
  }

  void _carregarTreinoPadrao() {
    setState(() {
      _fichasPorDia = {
        'Segunda': [
          ExerciseModel(
            name: 'Supino Reto com Halteres',
            sets: '4',
            reps: '10',
            loadKg: 20.0,
          ),
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ExerciseModel> exerciciosAtuais = _fichasPorDia[_diaSelecionado] ?? [];

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Fichas de Treino',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_suggest_rounded,
              color: brandOrange,
              size: 22,
            ),
            tooltip: 'Gerar Treino com IA',
            onPressed: _mostrarDialogoGerarOutroTreino,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: brandGreen),
                  SizedBox(height: 16),
                  Text(
                    'Carregando treino...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  height: 60,
                  color: cardBackground,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _diasSemana.length,
                    itemBuilder: (context, index) {
                      String dia = _diasSemana[index];
                      bool isSelected = _diaSelecionado == dia;
                      bool temTreino = _fichasPorDia.containsKey(dia);

                      return GestureDetector(
                        onTap: () => setState(() => _diaSelecionado = dia),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? brandGreen
                                : (temTreino ? cardBorder : Colors.transparent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dia,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : (temTreino ? Colors.white : Colors.grey),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ficha de $_diaSelecionado',
                              style: const TextStyle(
                                color: brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${exerciciosAtuais.length} Exercícios',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (exerciciosAtuais.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Nenhum treino programado para este dia.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...List.generate(exerciciosAtuais.length, (index) {
                          final exercise = exerciciosAtuais[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ExerciseCard(
                              exercise: exercise,
                              onCompleteSet: (restSeconds) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Descanso de ${restSeconds}s iniciado!',
                                    ),
                                    backgroundColor: brandGreen,
                                  ),
                                );
                              },
                              onUpdateLoad: (newLoad) {
                                setState(() {
                                  _fichasPorDia[_diaSelecionado]![index]
                                          .loadKg =
                                      newLoad;
                                });
                                _salvarNoSqlite(_fichasPorDia);
                              },
                              onWatchVideo: () {
                                _pesquisarEAbrirVideoYoutube(exercise.name);
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
