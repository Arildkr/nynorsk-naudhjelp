import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/question_repository.dart';
import '../models/question.dart';
import '../data/assessment_result_repository.dart';
import '../models/assessment_result.dart';
import '../../teacher_mode/data/student_config_provider.dart';
import '../../teacher_mode/data/teacher_repository.dart';
import '../../dashboard/data/xp_provider.dart';

final assessmentControllerProvider = StateNotifierProvider.autoDispose<AssessmentController, AsyncValue<AssessmentState>>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  final resultRepo = ref.watch(assessmentResultRepoProvider);
  final studentConfig = ref.watch(studentConfigProvider);
  final teacherRepo = ref.watch(teacherRepositoryProvider);
  final studentId = studentConfig != null ? ref.watch(studentIdProvider) : null;
  final xpNotifier = ref.read(xpProvider.notifier);
  return AssessmentController(repo, resultRepo, studentConfig, teacherRepo, studentId, xpNotifier);
});

enum AssessmentStatus { loading, active, saving, completed }

class AssessmentState {
  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final AssessmentStatus status;
  final String? syncError; // synleg Firebase-feil

  AssessmentState({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.status = AssessmentStatus.active,
    this.syncError,
  });

  bool get isCompleted => status == AssessmentStatus.completed;
  bool get isSaving => status == AssessmentStatus.saving;

  AssessmentState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, String>? answers,
    AssessmentStatus? status,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return AssessmentState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }

  Question get currentQuestion => questions[currentIndex];
}

class AssessmentController extends StateNotifier<AsyncValue<AssessmentState>> {
  final QuestionRepository _repo;
  final AssessmentResultRepository _resultRepo;
  final StudentConfig? _studentConfig;
  final TeacherRepository _teacherRepo;
  final String? _studentId;
  final XpNotifier _xpNotifier;

  AssessmentController(this._repo, this._resultRepo, this._studentConfig, this._teacherRepo, this._studentId, this._xpNotifier) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final questions = await _repo.getQuestionsForAssessment();
      state = AsyncValue.data(AssessmentState(questions: questions));
      await _pushToFirebase(0, 0, questions.length, false, '');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Returnerer feilmelding viss push feilar, null viss ok.
  Future<String?> _pushToFirebase(int score, int currentIndex, int total, bool isFinished, String weakCat, [Map<String, dynamic>? categoryScores]) async {
    if (_studentConfig == null || _studentId == null) return null;
    try {
      final data = {
        'name': _studentConfig!.name,
        'score': score,
        'totalQuestions': total,
        'isFinished': isFinished,
        'weakCategory': weakCat,
      };
      if (categoryScores != null) data['categoryScores'] = categoryScores;
      await _teacherRepo.updateStudentProgress(_studentConfig!.roomCode, _studentId!, data);
      debugPrint('Firebase push OK: score=$score/$total');
      return null;
    } catch (e) {
      debugPrint('Firebase-feil: $e');
      return e.toString();
    }
  }

  void answerCurrentQuestion(String answer) {
    state.whenData((s) async {
      final newAnswers = Map<String, String>.from(s.answers);
      newAnswers[s.currentQuestion.id] = answer;

      int score = 0;
      for (var q in s.questions) {
        if (newAnswers[q.id]?.toLowerCase() == q.correctAnswer.toLowerCase()) {
          score++;
        }
      }

      if (s.currentIndex < s.questions.length - 1) {
        // Mellomsteg — oppdater Firestore og gå til neste spørsmål
        final err = await _pushToFirebase(score, s.currentIndex + 1, s.questions.length, false, '');
        if (mounted) {
          state = AsyncValue.data(s.copyWith(
            answers: newAnswers,
            currentIndex: s.currentIndex + 1,
            syncError: err,
            clearSyncError: err == null,
          ));
        }
      } else {
        // Siste spørsmål
        if (mounted) {
          state = AsyncValue.data(s.copyWith(
            answers: newAnswers,
            status: AssessmentStatus.saving,
          ));
        }

        // Aggreger svar per kategori
        final Map<String, List<bool>> catAnswers = {};
        for (var q in s.questions) {
          final isCorrect = newAnswers[q.id]?.toLowerCase() == q.correctAnswer.toLowerCase();
          catAnswers.putIfAbsent(q.category, () => []).add(isCorrect);
        }
        final categoryResults = <String, bool>{};
        catAnswers.forEach((cat, results) {
          final correct = results.where((b) => b).length;
          categoryResults[cat] = correct >= (results.length / 2).ceil();
        });

        String weakCat = '';
        if (categoryResults.isNotEmpty) {
          final wrongCats = categoryResults.entries.where((e) => !e.value).map((e) => e.key).toList();
          if (wrongCats.isNotEmpty) weakCat = wrongCats.first;
        }

        // Build per-category Firebase payload
        final Map<String, dynamic> catPayload = {};
        catAnswers.forEach((cat, answers) {
          catPayload[cat] = {
            'correct': answers.where((b) => b).length,
            'total': answers.length,
          };
        });

        final firebaseErr = await _pushToFirebase(score, s.questions.length, s.questions.length, true, weakCat, catPayload);

        // Award XP: 5 per correct answer
        _xpNotifier.add(score * 5);

        try {
          await _resultRepo.saveResult(AssessmentResult(
            date: DateTime.now(),
            score: score,
            total: s.questions.length,
            categoryResults: categoryResults,
          ));
        } catch (e) {
          debugPrint('Lagring av resultat feilar: $e');
        }

        if (mounted) {
          state = AsyncValue.data(s.copyWith(
            answers: newAnswers,
            status: AssessmentStatus.completed,
            syncError: firebaseErr,
            clearSyncError: firebaseErr == null,
          ));
        }
      }
    });
  }
}
