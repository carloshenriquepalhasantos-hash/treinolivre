import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/student_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Salvar ou atualizar os dados do atleta no Firestore do Firebase
  Future<void> salvarAtletaNoFirebase(Student student, String email) async {
    try {
      // Usa o e-mail (em minúsculas) como ID único do documento no Firestore
      final String docId = email.trim().toLowerCase();

      await _firestore.collection('students').doc(docId).set({
        'name': student.name,
        'nickname': student.nickname,
        'weight': student.weight,
        'objective': student.objective,
        'water_goal_ml': student.waterGoalMl,
        'water_consumed_today': student.waterConsumedToday,
        'total_workouts': student.totalWorkouts,
        'is_expired': student.isExpired,
        'start_date': student.startDate.toIso8601String(),
        'end_date': student.endDate?.toIso8601String(),
        'profile_image_url': student.profileImageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao sincronizar atleta com o Firebase: $e');
    }
  }

  // Buscar dados do atleta no servidor do Firebase pelo e-mail
  Future<Student?> buscarAtletaNoFirebase(String email) async {
    try {
      final String docId = email.trim().toLowerCase();
      final docSnapshot = await _firestore
          .collection('students')
          .doc(docId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Student.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      debugPrint('Erro ao buscar atleta no Firebase: $e');
    }
    return null;
  }

  // --- NOVAS FUNÇÕES PARA O DIAGNÓSTICO 360° E IA ---

  // Salvar o Diagnóstico 360° respondido pelo utilizador vinculado ao UID
  Future<void> salvarDiagnostico360(
    String userId,
    Map<String, dynamic> dadosDiagnostico,
  ) async {
    try {
      await _firestore.collection('diagnosticos_360').doc(userId).set({
        ...dadosDiagnostico,
        'status': 'respondido',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar Diagnóstico 360 no Firebase: $e');
    }
  }

  // Verificar o status e dados do Diagnóstico 360° do utilizador
  Future<Map<String, dynamic>?> buscarDiagnostico360(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('diagnosticos_360')
          .doc(userId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
    } catch (e) {
      debugPrint('Erro ao buscar Diagnóstico 360 no Firebase: $e');
    }
    return null;
  }

  // Buscar o plano de treino gerado pela IA nos bastidores (Cloud Functions)
  Future<Map<String, dynamic>?> buscarTreinoGeradoPorIA(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('treinos_gerados')
          .doc(userId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
    } catch (e) {
      debugPrint('Erro ao buscar treino gerado por IA: $e');
    }
    return null;
  }
}
