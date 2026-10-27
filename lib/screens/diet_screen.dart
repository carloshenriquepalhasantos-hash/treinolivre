import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DietScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const DietScreen({super.key, this.userData});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  static const Color brandGreen = Color(0xFF22C55E);
  static const Color brandOrange = Color(0xFFF59E0B);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  bool _isLoading = true;
  List<Map<String, dynamic>> meals = [];
  Map<String, dynamic>? _dadosAtuais;

  // Controle local de itens checados por refeição e data do último reset (00:00)
  Map<int, Set<int>> _checkedMealsItems = {};
  DateTime _lastResetCheck = DateTime.now();

  final List<String> defaultObservations = [
    "Consumir de 3 a 4 litros de água diariamente.",
    "Evite usar açúcar. Para adoçar os alimentos e bebidas utilize os adoçantes: sucralose, stévia, eritritol ou xilitol.",
    "Açúcar mascavo e demerara também são açúcar, evite.",
    "Para preparar os alimentos prefira temperos naturais como alho, páprica, açafrão, chimichurri.",
    "Chás e cafés sem açúcar estão liberados à vontade.",
    "Refrigerantes zero podem ser usados livremente.",
    "Molhos zero calorias podem ser usados à vontade.",
    "Gelatina zero açúcar liberada para necessidade de doce.",
    "REFEIÇÃO LIVRE: UMA liberada na semana.",
    "Tire fotos de evolução frequentemente.",
  ];

  final List<String> _listaModelosIA = [
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-flash-latest',
  ];

  @override
  void initState() {
    super.initState();
    _verificarResetMeiaNoite();
    _carregarDieta();
  }

  void _verificarResetMeiaNoite() {
    final now = DateTime.now();
    if (_lastResetCheck.day != now.day ||
        _lastResetCheck.month != now.month ||
        _lastResetCheck.year != now.year) {
      setState(() {
        _checkedMealsItems.clear();
        _lastResetCheck = now;
      });
    }
  }

  Future<void> _carregarDieta() async {
    setState(() => _isLoading = true);

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
          debugPrint('Erro Firestore Dieta: $e');
        }
      }
    }

    _dadosAtuais = data;

    if (data != null && data.containsKey('planoTreinoIA')) {
      String planoIA = data['planoTreinoIA'] ?? '';
      meals = _parsearDietaJson(planoIA);
    }

    if (meals.isEmpty) {
      _carregarDietaPadrao();
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _parsearDietaJson(String entrada) {
    List<Map<String, dynamic>> resultado = [];
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

        if (mapaGeral.containsKey('dieta') && mapaGeral['dieta'] is List) {
          for (var item in mapaGeral['dieta']) {
            if (item is Map<String, dynamic>) {
              resultado.add({
                'time': item['time']?.toString() ?? '08:00',
                'title': item['title']?.toString() ?? 'REFEIÇÃO',
                'items': List<String>.from(item['items'] ?? []),
                'substitutions': List<String>.from(item['substitutions'] ?? []),
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao parsear dieta em JSON: $e');
    }
    return resultado;
  }

  void _carregarDietaPadrao() {
    meals = [
      {
        'time': '08:00',
        'title': 'CAFÉ DA MANHÃ',
        'items': [
          '4 Ovos inteiros (mexidos ou cozidos)',
          '2 Fatias de Pão Integral',
          '150g de Mamão',
          'Café preto sem açúcar',
        ],
        'substitutions': [
          'Ovos por 120g de frango desfiado',
          'Pão por 100g de tapioca',
        ],
      },
      {
        'time': '12:30',
        'title': 'ALMOÇO',
        'items': [
          '150g de Peito de Frango grelhado',
          '120g de Arroz Branco',
          'Salada verde à vontade',
          '1 Colher de sopa de azeite',
        ],
        'substitutions': [
          'Frango por Patinho moído',
          'Arroz por 150g de Batata Doce',
        ],
      },
      {
        'time': '16:00',
        'title': 'LANCHE DA TARDE',
        'items': [
          '30g de Whey Protein',
          '30g de Aveia em flocos',
          '1 Banana prata',
        ],
        'substitutions': [],
      },
      {
        'time': '20:00',
        'title': 'JANTAR',
        'items': [
          '150g de Peito de Frango grelhado',
          'Salada de folhas verdes à vontade',
        ],
        'substitutions': [],
      },
    ];
  }

  void _mostrarDialogoGerarDieta() {
    final TextEditingController caloriasController = TextEditingController(
      text: '2000',
    );
    final TextEditingController qtdRefeicoesController = TextEditingController(
      text: '4',
    );
    String modalidadeSelecionada = 'Flexível (Onívoro)';
    final List<String> modalidades = [
      'Flexível (Onívoro)',
      'Low Carb',
      'Cetogênica (Keto)',
      'Vegetariana',
      'High Protein (Hipertrofia)',
    ];

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
                    Icons.restaurant_menu,
                    color: brandOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Montar Nova Dieta com IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modalidade da Dieta:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButton<String>(
                        value: modalidadeSelecionada,
                        isExpanded: true,
                        dropdownColor: cardBackground,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: modalidades.map((mod) {
                          return DropdownMenuItem(
                            value: mod,
                            child: Text(
                              mod,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setDialogState(() => modalidadeSelecionada = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Meta de Calorias Diárias (kcal):',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: caloriasController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ex: 2000',
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
                    const SizedBox(height: 16),
                    const Text(
                      'Quantidade de Refeições:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtdRefeicoesController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ex: 4',
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
                  ],
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
                    Navigator.pop(context);
                    _gerarNovaDietaComIA(
                      modalidadeSelecionada,
                      caloriasController.text,
                      qtdRefeicoesController.text,
                    );
                  },
                  child: const Text(
                    'Gerar Dieta 🚀',
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

  Future<void> _gerarNovaDietaComIA(
    String modalidade,
    String calorias,
    String qtdRef,
  ) async {
    setState(() => _isLoading = true);

    final prompt =
        '''
      Atue como um Nutricionista Esportivo de elite. Crie um plano de dieta personalizado:
      - Modalidade: $modalidade
      - Calorias diárias: $calorias kcal
      - Quantidade exata de refeições: $qtdRef

      Responda ESTRITAMENTE em formato JSON válido contendo uma chave "dieta" que é uma lista de objetos de refeição. Cada refeição deve conter obrigatoriamente: "time" (ex: "08:00"), "title" (ex: "CAFÉ DA MANHÃ"), "items" (lista de strings com os alimentos e porções), e "substitutions" (lista de strings com opções de substituição).
      Retorne apenas o JSON puro.
    ''';

    List<Map<String, dynamic>> novasRefeicoes = [];

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
          int start = jsonText.indexOf('{');
          int end = jsonText.lastIndexOf('}');
          if (start != -1 && end != -1) {
            jsonText = jsonText.substring(start, end + 1);
            Map<String, dynamic> parsedMap = jsonDecode(jsonText);
            if (parsedMap.containsKey('dieta') && parsedMap['dieta'] is List) {
              for (var item in parsedMap['dieta']) {
                novasRefeicoes.add({
                  'time': item['time']?.toString() ?? '08:00',
                  'title': item['title']?.toString() ?? 'REFEIÇÃO',
                  'items': List<String>.from(item['items'] ?? []),
                  'substitutions': List<String>.from(
                    item['substitutions'] ?? [],
                  ),
                });
              }
            }
            if (novasRefeicoes.isNotEmpty) break;
          }
        }
      } catch (_) {}
    }

    if (novasRefeicoes.isNotEmpty) {
      setState(() {
        meals = novasRefeicoes;
        _checkedMealsItems.clear();
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Map<String, dynamic> planoAtualJson = {};
          if (_dadosAtuais != null &&
              _dadosAtuais!.containsKey('planoTreinoIA')) {
            try {
              String planoStr = _dadosAtuais!['planoTreinoIA'];
              String limpo = planoStr
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              int ini = limpo.indexOf('{');
              int fim = limpo.lastIndexOf('}');
              if (ini != -1 && fim != -1) {
                planoAtualJson = jsonDecode(limpo.substring(ini, fim + 1));
              }
            } catch (_) {}
          }

          planoAtualJson['dieta'] = meals;
          String novoPlanoStr = jsonEncode(planoAtualJson);

          if (_dadosAtuais != null) {
            _dadosAtuais!['planoTreinoIA'] = novoPlanoStr;
          }

          await FirebaseFirestore.instance
              .collection('diagnosticos_360')
              .doc(user.uid)
              .update({
                'planoTreinoIA': novoPlanoStr,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        }
      } catch (e) {
        debugPrint('Erro ao sincronizar nova dieta com Firebase: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nova dieta gerada e sincronizada com sucesso! 🚀'),
            backgroundColor: brandGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao gerar dieta. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    _verificarResetMeiaNoite();

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Sua Dieta',
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
            tooltip: 'Montar Dieta com IA',
            onPressed: _mostrarDialogoGerarDieta,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandGreen))
            : CustomScrollView(
                slivers: [
                  // LISTA DE REFEIÇÕES (MEAL CARDS)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _MealCard(
                        meal: meals[index],
                        index: index,
                        checkedItems: _checkedMealsItems[index] ?? {},
                        onItemToggled: (itemIdx) {
                          setState(() {
                            if (!_checkedMealsItems.containsKey(index)) {
                              _checkedMealsItems[index] = {};
                            }
                            if (_checkedMealsItems[index]!.contains(itemIdx)) {
                              _checkedMealsItems[index]!.remove(itemIdx);
                            } else {
                              _checkedMealsItems[index]!.add(itemIdx);
                            }
                          });
                        },
                        brandGreen: brandGreen,
                        brandOrange: brandOrange,
                        cardBackground: cardBackground,
                        cardBorder: cardBorder,
                      );
                    }, childCount: meals.length),
                  ),

                  // OBSERVAÇÕES FIXAS DA DIETA
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: brandOrange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Observações Importantes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...defaultObservations.map(
                            (obs) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      color: brandOrange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      obs,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }
}

// === COMPONENTE MEAL CARD ===
class _MealCard extends StatefulWidget {
  final Map<String, dynamic> meal;
  final int index;
  final Set<int> checkedItems;
  final Function(int) onItemToggled;
  final Color brandGreen;
  final Color brandOrange;
  final Color cardBackground;
  final Color cardBorder;

  const _MealCard({
    required this.meal,
    required this.index,
    required this.checkedItems,
    required this.onItemToggled,
    required this.brandGreen,
    required this.brandOrange,
    required this.cardBackground,
    required this.cardBorder,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _expanded = false;

  void _showSubstitutions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.cardBorder),
        ),
        title: Text(
          'Substituições - ${widget.meal['title']}',
          style: TextStyle(
            color: widget.brandOrange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: (widget.meal['substitutions'] as List<String>)
              .map(
                (sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        color: widget.brandOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = widget.meal['items'] ?? [];
    final bool allChecked =
        items.isNotEmpty && widget.checkedItems.length == items.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: widget.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allChecked ? widget.brandGreen : widget.cardBorder,
        ),
        boxShadow: allChecked
            ? [
                BoxShadow(
                  color: widget.brandGreen.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(
              Icons.access_time_rounded,
              color: allChecked ? widget.brandGreen : widget.brandOrange,
            ),
            title: Text(
              widget.meal['title'] ?? 'REFEIÇÃO',
              style: TextStyle(
                color: allChecked ? widget.brandGreen : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                decoration: allChecked ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              widget.meal['time'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.checkedItems.length}/${items.length}',
                  style: TextStyle(
                    color: allChecked ? widget.brandGreen : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: widget.cardBorder),
                  ...items.asMap().entries.map((entry) {
                    final isChecked = widget.checkedItems.contains(entry.key);
                    return GestureDetector(
                      onTap: () => widget.onItemToggled(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              isChecked
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isChecked
                                  ? widget.brandGreen
                                  : Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: isChecked ? Colors.grey : Colors.white,
                                  fontSize: 14,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if ((widget.meal['substitutions'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () => _showSubstitutions(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              color: widget.brandOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ver substituições',
                              style: TextStyle(
                                color: widget.brandOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
