import '../models/student_model.dart';

class StudentRepository {
  // Lista em memória armazenando os alunos durante a sessão de testes
  static final List<Student> _students = [
    Student(
      id: 1,
      name: 'Carlos Santos',
      nickname: 'carlos',
      password: '1234',
      weight: 80.0,
      objective: 'Hipertrofia',
      startDate: DateTime(2026, 1, 1),
    ),
    Student(
      id: 2,
      name: 'Ana Silva',
      nickname: 'anac',
      password: '4321',
      weight: 65.0,
      objective: 'Emagrecimento',
      startDate: DateTime(2026, 1, 15),
    ),
  ];

  // Retorna a lista completa de alunos
  static List<Student> getStudents() {
    return _students;
  }

  // Adiciona um novo aluno na lista em memória
  static void addStudent(Student student) {
    _students.add(student);
  }
}
