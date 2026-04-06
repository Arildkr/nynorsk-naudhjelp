import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assessment/data/question_repository.dart';
import '../../assessment/data/assessment_result_repository.dart';
import '../../assessment/models/question.dart';
import '../../assessment/presentation/assessment_controller.dart';

// Null = skreddarsydd (basert på svake kategoriar), non-null = spesifikk kategori
final practiceControllerProvider = StateNotifierProvider.autoDispose
    .family<PracticeController, AsyncValue<AssessmentState>, String?>(
  (ref, category) {
    final repo = ref.watch(questionRepositoryProvider);
    final resultRepo = ref.watch(assessmentResultRepoProvider);
    return PracticeController(repo, resultRepo, category);
  },
);

class PracticeController extends StateNotifier<AsyncValue<AssessmentState>> {
  final QuestionRepository _repo;
  final AssessmentResultRepository _resultRepo;
  final String? _category;

  PracticeController(this._repo, this._resultRepo, this._category)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final List<Question> questions;
      if (_category != null) {
        questions = await _repo.getQuestionsForCategory(_category!);
      } else {
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
        questions = await _repo.getQuestionsForPractice(categoryMastery);
      }
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
        state = AsyncValue.data(s.copyWith(
          answers: newAnswers,
          status: AssessmentStatus.completed,
        ));
      }
    });
  }
}
