import 'package:flutter/material.dart';

import 'diagnosis.dart'; // Importe sua tela do formulário criada antes

class MainNavigationScreen extends StatefulWidget {
  final String studentStatus; // 'nao_enviado', 'pendente', 'revisado'

  const MainNavigationScreen({super.key, required this.studentStatus});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.studentStatus;
  }

  @override
  Widget build(BuildContext context) {
    // Se o status NÃO for 'revisado', bloqueamos as abas de Treino e Dieta
    bool isBlocked = _currentStatus != 'revisado';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C12),
      body: isBlocked ? _buildBlockedView(context) : _buildAllowedView(),
      bottomNavigationBar: isBlocked
          ? null // Oculta a barra se estiver bloqueado ou mostra apenas configurações
          : NavigationBar(
              backgroundColor: const Color(0xFF14131A),
              indicatorColor: const Color(0xFF8B5CF6),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fitness_center, color: Colors.white70),
                  selectedIcon: Icon(Icons.fitness_center, color: Colors.white),
                  label: 'Treino',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant, color: Colors.white70),
                  selectedIcon: Icon(Icons.restaurant, color: Colors.white),
                  label: 'Dieta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings, color: Colors.white70),
                  selectedIcon: Icon(Icons.settings, color: Colors.white),
                  label: 'Config',
                ),
              ],
            ),
    );
  }

  // --- TELA DE BLOQUEIO / AVISO (QUESTIONÁRIO PENDENTE OU NÃO ENVIADO) ---
  Widget _buildBlockedView(BuildContext context) {
    bool isPending = _currentStatus == 'pendente';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF22212C),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPending
                      ? Colors.amberAccent
                      : const Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              child: Icon(
                isPending ? Icons.hourglass_top : Icons.assignment_outlined,
                size: 48,
                color: isPending ? Colors.amberAccent : const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPending
                  ? 'Avaliação Pendente'
                  : 'Questionário 360° Obrigatório',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPending
                  ? 'Seu Diagnóstico 360° foi enviado e está aguardando o treinador validar e liberar seus treinos e dieta.'
                  : 'Para liberar o acesso aos seus treinos, dieta e acompanhamento, é obrigatório responder o Diagnóstico 360° completo.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!isPending) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Diagnosis360Screen(
                        onSubmit: (data) {
                          // Aqui você atualiza o status no seu banco/estado para 'pendente'
                          setState(() {
                            _currentStatus = 'pendente';
                          });
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  'Responder Questionário 360°',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () {
                  // Botão opcional para revisar o que foi enviado ou atualizar status
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aguarde a validação do seu treinador.'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text(
                  'Verificar Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TELA LIBERADA (TREINO, DIETA E CONFIG) ---
  Widget _buildAllowedView() {
    final List<Widget> screens = [
      const Center(
        child: Text(
          'Tela de Treinos (Liberado)',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      const Center(
        child: Text(
          'Tela de Dieta (Liberado)',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      const Center(
        child: Text(
          'Tela de Configurações',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    ];

    return screens[_currentIndex];
  }
}
