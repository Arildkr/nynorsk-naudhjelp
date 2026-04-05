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

  StudentProgress({
    required this.id,
    required this.name,
    required this.score,
    required this.totalQuestions,
    required this.isFinished,
    required this.weakCategory,
  });

  factory StudentProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentProgress(
      id: doc.id,
      name: data['name'] ?? 'Ukjent',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      isFinished: data['isFinished'] ?? false,
      weakCategory: data['weakCategory'] ?? '',
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

  Stream<List<StudentProgress>> watchRoom(String roomCode) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('students')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StudentProgress.fromFirestore(doc)).toList();
    });
  }
}
