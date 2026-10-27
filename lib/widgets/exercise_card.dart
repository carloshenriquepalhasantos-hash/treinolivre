import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/workout_model.dart';

class ExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  final Function(int restSeconds) onCompleteSet;
  final Function(double newLoad) onUpdateLoad;
  final Function(String videoUrl2)? onUpdateVideo2;
  final VoidCallback? onWatchVideo;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onCompleteSet,
    required this.onUpdateLoad,
    this.onUpdateVideo2,
    this.onWatchVideo,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  // Cores da Nova Identidade Visual (Baseadas no Logótipo)
  static const Color brandGreen = Color(0xFF22C55E);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color darkBackground = Color(0xFF0A0E0B);
  static const Color cardBackground = Color(0xFF141C16);
  static const Color cardBorder = Color(0xFF233528);

  bool _expanded = false;
  bool _editingLoad = false;
  late double _tempLoad;

  // Controle do input e exibição do Link do Vídeo 2
  bool _showVideo2Input = false;
  final TextEditingController _video2Controller = TextEditingController();

  // Controle do Timer de Descanso
  bool _isResting = false;
  int _restTimer = 0;
  Timer? _restInterval;

  @override
  void initState() {
    super.initState();
    _tempLoad = widget.exercise.loadKg;
    _restTimer = widget.exercise.restSeconds ?? 60;
  }

  void _startInlineRest() {
    final restDuration = widget.exercise.restSeconds ?? 60;
    setState(() {
      _isResting = true;
      _restTimer = restDuration;
    });

    _restInterval?.cancel();
    _restInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimer > 0) {
        setState(() {
          _restTimer--;
        });
      } else {
        _restInterval?.cancel();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  // Simulação do player de vídeo flutuante
  void _simulateVideoPlayer(String videoTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: brandGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                videoTitle,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        content: Container(
          height: 180,
          decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Simulação de Player de Vídeo\n(Reproduzindo execução correta)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
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
  void dispose() {
    _restInterval?.cancel();
    _video2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = int.tryParse(widget.exercise.sets.toString()) ?? 3;
    final isFullyDone = widget.exercise.completedSets >= totalSets;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFullyDone ? brandGreen : cardBorder),
      ),
      child: Column(
        children: [
          // 1. HEADER (Card Recolhido / Fechado)
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFullyDone
                    ? brandGreen.withValues(alpha: 0.15)
                    : darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFullyDone ? brandGreen : cardBorder,
                ),
              ),
              child: Icon(
                isFullyDone
                    ? Icons.check_circle_rounded
                    : Icons.fitness_center_rounded,
                color: isFullyDone ? brandGreen : brandGreen,
                size: 20,
              ),
            ),
            title: Text(
              widget.exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildBadge(
                    '${widget.exercise.sets} séries',
                    brandGreen,
                    brandGreen.withValues(alpha: 0.15),
                  ),
                  _buildBadge(
                    '${widget.exercise.reps} reps',
                    Colors.grey.shade300,
                    darkBackground,
                  ),
                  _buildBadge(
                    '${widget.exercise.restSeconds ?? 60}s',
                    brandBlue,
                    brandBlue.withValues(alpha: 0.15),
                  ),
                  if (widget.exercise.loadKg > 0)
                    _buildBadge(
                      '${widget.exercise.loadKg}kg',
                      Colors.amber,
                      Colors.amber.withValues(alpha: 0.15),
                    ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.exercise.completedSets}/$totalSets',
                  style: TextStyle(
                    color: isFullyDone ? brandGreen : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // 2. ESTADO EXPANDIDO (Aberto)
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BLOCO A — Estatísticas (3 colunas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          title: 'SÉRIES',
                          value: widget.exercise.sets.toString(),
                          valueColor: brandGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox(
                          title: 'REPS',
                          value: widget.exercise.reps.toString(),
                          valueColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricBox(
                          title: 'DESCANSO',
                          value: '${widget.exercise.restSeconds ?? 60}s',
                          valueColor: brandBlue,
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // BLOCO B — Carga (kg) Editável
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: darkBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CARGA UTILIZADA:',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_editingLoad)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _editingLoad = true),
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: brandBlue,
                            ),
                            label: Text(
                              '${widget.exercise.loadKg} kg',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                height: 32,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) => _tempLoad =
                                      double.tryParse(val) ??
                                      widget.exercise.loadKg,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: brandGreen,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _editingLoad = false);
                                  widget.onUpdateLoad(_tempLoad);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nota do Treinador (se houver)
                  if (widget.exercise.note != null &&
                      widget.exercise.note!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: brandGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '💡 Nota do Treinador: ${widget.exercise.note}',
                        style: const TextStyle(color: brandGreen, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // BOTÕES DE VÍDEO (Vídeo 1 e Vídeo 2)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateVideoPlayer(
                            'Vídeo 1: ${widget.exercise.name}',
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: brandGreen.withValues(alpha: 0.1),
                            side: BorderSide(
                              color: brandGreen.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: brandGreen,
                            size: 16,
                          ),
                          label: const Text(
                            'Vídeo 1',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _simulateVideoPlayer(
                            'Vídeo 2: ${widget.exercise.name}',
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: brandGreen.withValues(alpha: 0.1),
                            side: BorderSide(
                              color: brandGreen.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: brandGreen,
                            size: 16,
                          ),
                          label: const Text(
                            'Vídeo 2',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Adicionar Link do Vídeo 2
                  if (!_showVideo2Input)
                    TextButton.icon(
                      onPressed: () => setState(() => _showVideo2Input = true),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: brandBlue,
                      ),
                      label: const Text(
                        '+ Adicionar Link Vídeo 2',
                        style: TextStyle(
                          color: brandBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _video2Controller,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cole a URL do vídeo 2...',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                filled: true,
                                fillColor: darkBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: cardBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: brandGreen,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() => _showVideo2Input = false);
                            if (widget.onUpdateVideo2 != null) {
                              widget.onUpdateVideo2!(_video2Controller.text);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Link do Vídeo 2 salvo com sucesso!',
                                ),
                                backgroundColor: brandGreen,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // BLOCO C — Progresso das Séries (Quadrados Numerados)
                  const Text(
                    'PROGRESSO DAS SÉRIES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(totalSets, (index) {
                      bool isCompletedSet =
                          index < widget.exercise.completedSets;
                      bool isCurrentSet =
                          index == widget.exercise.completedSets;

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < totalSets - 1 ? 6 : 0,
                          ),
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCompletedSet
                                ? brandGreen.withValues(alpha: 0.2)
                                : isCurrentSet
                                ? brandGreen.withValues(alpha: 0.1)
                                : darkBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompletedSet || isCurrentSet
                                  ? brandGreen
                                  : cardBorder,
                            ),
                          ),
                          child: isCompletedSet
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: brandGreen,
                                  size: 18,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrentSet
                                        ? brandGreen
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // BOTÃO DE AÇÃO DO RODAPÉ (Série X de Y / Descanso / Concluído)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFullyDone
                            ? const Color(0xFF1B3822)
                            : _isResting
                            ? brandBlue
                            : brandGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isFullyDone
                          ? null
                          : _isResting
                          ? () {
                              // Toque para pular o descanso
                              _restInterval?.cancel();
                              setState(() => _isResting = false);
                            }
                          : () {
                              setState(() {
                                widget.exercise.completedSets++;
                              });
                              if (widget.exercise.completedSets < totalSets) {
                                _startInlineRest();
                              }
                              widget.onCompleteSet(
                                widget.exercise.restSeconds ?? 60,
                              );
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFullyDone
                                ? Icons.check_circle_rounded
                                : _isResting
                                ? Icons.timer_rounded
                                : Icons.play_arrow_rounded,
                            color: isFullyDone ? brandGreen : Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFullyDone
                                ? 'EXERCÍCIO CONCLUÍDO'
                                : _isResting
                                ? 'DESCANSO: ${_restTimer}s (Toque para pular)'
                                : 'CONCLUIR SÉRIE (${widget.exercise.completedSets + 1}/$totalSets)',
                            style: TextStyle(
                              color: isFullyDone ? brandGreen : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required Color valueColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? brandBlue.withValues(alpha: 0.4) : cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
