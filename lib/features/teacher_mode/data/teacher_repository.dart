import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

class StudentProgress {
  final String id;
  final String name;
  final int score;
  final int totalQuestions;
  final bool isFinished;
  final String weakCategory;
  final Map<String, Map<String, int>> categoryScores; // cat -> {correct, total}

  StudentProgress({
    required this.id,
    required this.name,
    required this.score,
    required this.totalQuestions,
    required this.isFinished,
    required this.weakCategory,
    required this.categoryScores,
  });

  factory StudentProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, Map<String, int>> catScores = {};
    final raw = data['categoryScores'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          catScores[k.toString()] = {
            'correct': (v['correct'] as num?)?.toInt() ?? 0,
            'total': (v['total'] as num?)?.toInt() ?? 0,
          };
        }
      });
    }
    return StudentProgress(
      id: doc.id,
      name: data['name'] ?? 'Ukjent',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      isFinished: data['isFinished'] ?? false,
      weakCategory: data['weakCategory'] ?? '',
      categoryScores: catScores,
    );
  }
}

class TeacherRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRoom(String roomCode) async {
    await _firestore.collection('rooms').doc(roomCode).set({
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> updateStudentProgress(String roomCode, String studentId, Map<String, dynamic> data) async {
    await _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('students')
        .doc(studentId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> removeStudent(String roomCode, String studentId) async {
    await _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  Stream<List<StudentProgress>> watchRoom(String roomCode) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentProgress.fromFirestore(doc))
            .where((s) => s.id != '__test__')
            .toList());
  }
}
