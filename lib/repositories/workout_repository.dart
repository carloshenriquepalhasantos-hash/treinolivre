import '../models/workout_model.dart';

class WorkoutRepository {
  static const List<String> days = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

  // CORREÇÃO 1: Alterado de List<ExerciseModel> para List<WorkoutProtocol>
  static List<WorkoutProtocol> getMockWorkouts() {
    final todayName = days[DateTime.now().weekday % 7];

    return [
      WorkoutProtocol(
        id: '1',
        name: 'Treino A - Membros Superiores (Peito e Tríceps)',
        dayOfWeek: todayName,
        order: 1,
        exercises: [
          ExerciseModel(
            name: 'Supino Reto com Halteres',
            sets: '4', // CORREÇÃO 2: O número 4 agora é uma String ('4')
            reps: '10-12',
            restSeconds: 60,
            loadKg: 26.0,
            note: 'Manter a escápula retraída e controlar a descida.',
          ),
          ExerciseModel(
            name: 'Supino Inclinado na Polia',
            sets: '3', // O número 3 agora é uma String ('3')
            reps: '12',
            restSeconds: 45,
            loadKg: 20.0,
          ),
          ExerciseModel(
            name: 'Tríceps Corda',
            sets: '4',
            reps: '12-15',
            restSeconds: 45,
            loadKg: 15.0,
          ),
        ],
      ),
      WorkoutProtocol(
        id: '2',
        name: 'Treino B - Membros Inferiores',
        dayOfWeek: days[(DateTime.now().weekday + 1) % 7], // Amanhã
        order: 2,
        exercises: [
          ExerciseModel(
            name: 'Agachamento Livre',
            sets: '4',
            reps: '8-10',
            restSeconds: 90,
            loadKg: 60.0,
          ),
          ExerciseModel(
            name: 'Leg Press 45',
            sets: '4',
            reps: '10-12',
            restSeconds: 60,
            loadKg: 120.0,
          ),
        ],
      ),
    ];
  }
}
