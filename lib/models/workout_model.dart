class WorkoutProtocol {
  final dynamic id; // Usado 'dynamic' para aceitar tanto Strings antigas quanto Ints do SQLite
  final int studentId;
  final String name;
  final String dayOfWeek;
  final int order;
  final List<ExerciseModel> exercises;

  WorkoutProtocol({
    this.id,
    this.studentId = 0, // Padrão 0 para não quebrar telas antigas
    required this.name,
    required this.dayOfWeek,
    this.order = 0,
    required this.exercises,
  });

  // Mapeamento CORRETO para o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'title':
          name, // O banco espera a coluna 'title', mapeamos o 'name' para ela
      'dayOfWeek': dayOfWeek,
    };
  }

  // CORREÇÃO 1: Este factory agora está DENTRO da classe
  factory WorkoutProtocol.fromMap(
    Map<String, dynamic> map, {
    required List<ExerciseModel> exercises,
  }) {
    return WorkoutProtocol(
      id: map['id'],
      studentId: map['studentId'] as int? ?? 0,
      name: map['title']?.toString() ?? map['name']?.toString() ?? '',
      dayOfWeek: map['dayOfWeek']?.toString() ?? '',
      order: map['order'] as int? ?? 0,
      exercises: exercises,
    );
  }
}

class ExerciseModel {
  final dynamic id;
  final dynamic workoutId;
  final String name;
  final String sets;
  final String reps;
  double loadKg;
  bool isCompleted;

  // CORREÇÃO 2: Propriedades necessárias para o ExerciseCard funcionar
  int completedSets;
  int? restSeconds;
  String? note;

  ExerciseModel({
    this.id,
    this.workoutId,
    required this.name,
    required this.sets,
    required this.reps,
    this.loadKg = 0.0,
    this.isCompleted = false,
    this.completedSets = 0,
    this.restSeconds,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': loadKg, // Banco espera 'weight', modelo usa 'loadKg'
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // CORREÇÃO 3: Faltava o método fromMap para o banco conseguir ler os exercícios
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'],
      workoutId: map['workoutId'],
      name: map['name']?.toString() ?? '',
      sets: map['sets']?.toString() ?? '3',
      reps: map['reps']?.toString() ?? '10',
      // Lê de 'weight' do banco ou de 'loadKg'
      loadKg:
          (map['weight'] as num?)?.toDouble() ??
          (map['loadKg'] as num?)?.toDouble() ??
          0.0,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }
}

class Cardio {
  final String name;
  final String duration;

  Cardio({required this.name, required this.duration});
}
