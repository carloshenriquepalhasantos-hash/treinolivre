import 'dart:async';

import 'package:flutter/material.dart';

class RestTimerModal extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onClose;

  const RestTimerModal({
    super.key,
    required this.initialSeconds,
    required this.onClose,
  });

  @override
  State<RestTimerModal> createState() => _RestTimerModalState();
}

class _RestTimerModalState extends State<RestTimerModal> {
  late int timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    timeLeft = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        _timer?.cancel();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF14131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TEMPO DE DESCANSO',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _formatTime(timeLeft),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    timeLeft += 15;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.purple),
                ),
                child: const Text(
                  '+15s',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text(
                  'Pular Descanso',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
