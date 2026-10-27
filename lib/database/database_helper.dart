import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/workout_model.dart';
import '../models/student_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _databaseVersion = 3;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('treinolivre.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela de Alunos
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        nickname TEXT NOT NULL,
        password TEXT NOT NULL,
        isExpired INTEGER DEFAULT 0
      )
    ''');

    // Tabela de Treinos
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        title TEXT NOT NULL,
        dayOfWeek TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Exercícios
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps TEXT NOT NULL,
        weight REAL DEFAULT 0.0,
        isCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          studentId INTEGER NOT NULL,
          title TEXT NOT NULL,
          dayOfWeek TEXT NOT NULL,
          FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workoutId INTEGER NOT NULL,
          name TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps TEXT NOT NULL,
          weight REAL DEFAULT 0.0,
          isCompleted INTEGER DEFAULT 0,
          FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // --- MÉTODOS CRUD: ALUNOS E AUTENTICAÇÃO ---

  Future<int> insertStudent(Student student) async {
    final db = await instance.database;
    return await db.insert('students', student.toMap());
  }

  Future<int> createUser(Student student) async {
    return await insertStudent(student);
  }

  Future<List<Student>> getStudents({String? query}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result;

    if (query != null && query.trim().isNotEmpty) {
      result = await db.query(
        'students',
        where: 'name LIKE ? OR nickname LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
    } else {
      result = await db.query('students');
    }

    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<List<Student>> getAllStudents() async => await getStudents();
  Future<List<Student>> getAllUsers() async => await getStudents();

  Future<Student?> getUserByIdentifier(String identifier) async {
    final db = await instance.database;
    final result = await db.query(
      'students',
      where: 'nickname = ?',
      whereArgs: [identifier],
    );

    if (result.isNotEmpty) {
      return Student.fromMap(result.first);
    }
    return null;
  }

  // --- MÉTODOS CRUD: TREINOS E EXERCÍCIOS ---

  Future<int> insertWorkout(WorkoutProtocol workout) async {
    final db = await instance.database;
    final workoutId = await db.insert('workouts', workout.toMap());

    for (var exercise in workout.exercises) {
      final exerciseMap = exercise.toMap();
      exerciseMap['workoutId'] = workoutId;
      await db.insert('exercises', exerciseMap);
    }

    return workoutId;
  }

  Future<List<WorkoutProtocol>> getWorkoutsByStudent(int studentId) async {
    final db = await instance.database;
    final workoutMaps = await db.query(
      'workouts',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );

    List<WorkoutProtocol> workouts = [];

    for (var map in workoutMaps) {
      final exercises = await getExercisesByWorkout(map['id'] as int);
      workouts.add(WorkoutProtocol.fromMap(map, exercises: exercises));
    }

    return workouts;
  }

  Future<List<ExerciseModel>> getExercisesByWorkout(int workoutId) async {
    final db = await instance.database;
    final result = await db.query(
      'exercises',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );

    return result.map((map) => ExerciseModel.fromMap(map)).toList();
  }

  Future<int> updateExerciseStatus(int exerciseId, bool isCompleted) async {
    final db = await instance.database;
    return await db.update(
      'exercises',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }
}
