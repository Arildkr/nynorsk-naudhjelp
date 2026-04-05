import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assessment/data/question_repository.dart';
import '../../assessment/data/assessment_result_repository.dart';
import '../../assessment/presentation/assessment_controller.dart';

final practiceControllerProvider = StateNotifierProvider.autoDispose<PracticeController, AsyncValue<AssessmentState>>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  final resultRepo = ref.watch(assessmentResultRepoProvider);
  return PracticeController(repo, resultRepo);
});

class PracticeController extends StateNotifier<AsyncValue<AssessmentState>> {
  final QuestionRepository _repo;
  final AssessmentResultRepository _resultRepo;

  PracticeController(this._repo, this._resultRepo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final history = _resultRepo.getHistory();
      
      final Map<String, List<int>> stats = {};
      for (var res in history) {
        res.categoryResults.forEach((cat, isCorrect) {
          if (!stats.containsKey(cat)) stats[cat] = [0, 0];
          stats[cat]![0] += isCorrect ? 1 : 0;
          stats[cat]![1] += 1;
        });
      }

      final Map<String, double> categoryMastery = {};
      stats.forEach((key, val) {
         categoryMastery[key] = val[1] > 0 ? (val[0] / val[1]) : 0.0;
      });

      final questions = await _repo.getQuestionsForPractice(categoryMastery);
      state = AsyncValue.data(AssessmentState(questions: questions));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void answerCurrentQuestion(String answer) {
    state.whenData((s) {
      final newAnswers = Map<String, String>.from(s.answers);
      newAnswers[s.currentQuestion.id] = answer;

      if (s.currentIndex < s.questions.length - 1) {
        state = AsyncValue.data(s.copyWith(
          answers: newAnswers,
          currentIndex: s.currentIndex + 1,
        ));
      } else {
        // I øving lagrar me ikkje score-historikk, sidan det kan påverke
        // standardmålinga (kartlegging). Held dei åtskilde med vilje.
        state = AsyncValue.data(s.copyWith(
          answers: newAnswers,
          status: AssessmentStatus.completed,
        ));
      }
    });
  }
}
