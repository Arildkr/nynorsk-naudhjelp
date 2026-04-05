import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/question_repository.dart';
import '../models/question.dart';
import '../data/assessment_result_repository.dart';
import '../models/assessment_result.dart';
import '../../teacher_mode/data/student_config_provider.dart';
import '../../teacher_mode/data/teacher_repository.dart';
import 'dart:math';

final assessmentControllerProvider = StateNotifierProvider.autoDispose<AssessmentController, AsyncValue<AssessmentState>>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  final resultRepo = ref.watch(assessmentResultRepoProvider);
  final studentConfig = ref.watch(studentConfigProvider);
  final teacherRepo = ref.watch(teacherRepositoryProvider);
  final studentId = studentConfig != null ? Random().nextInt(999999).toString() : null;
  return AssessmentController(repo, resultRepo, studentConfig, teacherRepo, studentId);
});

class AssessmentState {
  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final bool isCompleted;

  AssessmentState({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.isCompleted = false,
  });

  AssessmentState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<String, String>? answers,
    bool? isCompleted,
  }) {
    return AssessmentState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
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

  AssessmentController(this._repo, this._resultRepo, this._studentConfig, this._teacherRepo, this._studentId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final questions = await _repo.getQuestionsForAssessment();
      state = AsyncValue.data(AssessmentState(questions: questions));
      _pushToFirebase(0, 0, questions.length, false, '');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _pushToFirebase(int score, int currentIndex, int total, bool isFinished, String weakCat) {
    if (_studentConfig != null && _studentId != null) {
      try {
        _teacherRepo.updateStudentProgress(_studentConfig!.roomCode, _studentId!, {
          'name': _studentConfig!.name,
          'score': score,
          'totalQuestions': total,
          'isFinished': isFinished,
          'weakCategory': weakCat,
        });
      } catch (e) {
         // Silently ignore if offline
      }
    }
  }

  void answerCurrentQuestion(String answer) {
    state.whenData((s) {
      final newAnswers = Map<String, String>.from(s.answers);
      newAnswers[s.currentQuestion.id] = answer;

      int score = 0;
      for (var q in s.questions) {
        if (newAnswers[q.id]?.toLowerCase() == q.correctAnswer.toLowerCase()) {
          score++;
        }
      }

      if (s.currentIndex < s.questions.length - 1) {
        _pushToFirebase(score, s.currentIndex + 1, s.questions.length, false, '');
        state = AsyncValue.data(s.copyWith(
          answers: newAnswers,
          currentIndex: s.currentIndex + 1,
        ));
      } else {
        // Aggreger svar per kategori — fleire spørsmål per kategori
        final Map<String, List<bool>> catAnswers = {};
        for (var q in s.questions) {
          final isCorrect = newAnswers[q.id]?.toLowerCase() == q.correctAnswer.toLowerCase();
          catAnswers.putIfAbsent(q.category, () => []).add(isCorrect);
        }
        // Kategorien er "meistra" om fleirtalet av svar er rette
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

        _pushToFirebase(score, s.questions.length, s.questions.length, true, weakCat);

        _resultRepo.saveResult(AssessmentResult(
          date: DateTime.now(),
          score: score,
          total: s.questions.length,
          categoryResults: categoryResults,
        ));

        state = AsyncValue.data(s.copyWith(
          answers: newAnswers,
          isCompleted: true,
        ));
      }
    });
  }
}
