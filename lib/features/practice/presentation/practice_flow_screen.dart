import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'practice_controller.dart';
import '../../assessment/presentation/assessment_controller.dart';
import '../../assessment/models/question.dart';
import '../../assessment/presentation/widgets/multiple_choice_widget.dart';
import '../../assessment/presentation/widgets/swipe_choice_widget.dart';
import '../../assessment/presentation/widgets/fill_in_widget.dart';
import '../../assessment/presentation/widgets/true_false_widget.dart';
import '../../assessment/presentation/widgets/matching_widget.dart';

class PracticeFlowScreen extends ConsumerStatefulWidget {
  const PracticeFlowScreen({super.key});

  @override
  ConsumerState<PracticeFlowScreen> createState() => _PracticeFlowScreenState();
}

class _PracticeFlowScreenState extends ConsumerState<PracticeFlowScreen> {
  int _streak = 0;
  int _xp = 0;
  bool _showXpBump = false;
  int _lastXpGain = 0;

  void _handleAnswer(String answer, Question q) {
    final isCorrect = answer.toLowerCase() == q.correctAnswer.toLowerCase();

    setState(() {
      if (isCorrect) {
        _streak++;
        final bonus = _streak >= 3 ? 5 : 0; // streak bonus
        _lastXpGain = 10 + bonus;
        _xp += _lastXpGain;
        _showXpBump = true;
      } else {
        _streak = 0;
        _lastXpGain = 0;
      }
    });

    if (_showXpBump) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showXpBump = false);
      });
    }

    ref.read(practiceControllerProvider.notifier).answerCurrentQuestion(answer);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(practiceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spesialøving'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (_streak >= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                label: Text('$_streak', style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.orange.shade50,
                padding: EdgeInsets.zero,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showXpBump
                  ? Text(
                      '+$_lastXpGain XP',
                      key: const ValueKey('xp_bump'),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    )
                  : Text(
                      '$_xp XP',
                      key: const ValueKey('xp_total'),
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Feil oppsto: $err')),
        data: (state) {
          if (state.questions.isEmpty) {
            return const Center(child: Text('Fant ingen spørsmål i banken.'));
          }

          if (state.isCompleted) {
            return _buildResult(context, state);
          }

          final q = state.currentQuestion;
          final progress = state.currentIndex / state.questions.length;

          return SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.teal,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildQuestionWidget(q),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionWidget(Question q) {
    switch (q.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: q,
          isPractice: true,
          onAnswered: (answer) => _handleAnswer(answer, q),
        );
      case QuestionType.swipeChoice:
        return SwipeChoiceWidget(
          question: q,
          isPractice: true,
          onAnswered: (answer) => _handleAnswer(answer, q),
        );
      case QuestionType.fillIn:
        return FillInWidget(
          question: q,
          isPractice: true,
          onAnswered: (answer) => _handleAnswer(answer, q),
        );
      case QuestionType.trueOrFalse:
        return TrueFalseWidget(
          question: q,
          isPractice: true,
          onAnswered: (answer) => _handleAnswer(answer, q),
        );
      case QuestionType.matching:
        return MatchingWidget(
          question: q,
          isPractice: true,
          onAnswered: (answer) => _handleAnswer(answer, q),
        );
    }
  }

  Widget _buildResult(BuildContext context, AssessmentState state) {
    int score = 0;
    for (var q in state.questions) {
      final answer = state.answers[q.id];
      if (answer != null && answer.toLowerCase() == q.correctAnswer.toLowerCase()) {
        score++;
      }
    }

    final total = state.questions.length;
    final pct = score / total;
    final stars = pct >= 0.85 ? 3 : pct >= 0.55 ? 2 : 1;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber.shade600,
                  size: 56,
                ),
              )),
            ),
            const SizedBox(height: 20),
            Text(
              stars == 3 ? 'Strålande! 🏆' : stars == 2 ? 'Bra jobba! 💪' : 'Hald fram! 📚',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Text(
              '$score av $total riktige',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${(pct * 100).round()} %',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // XP badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade300, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Du fekk', style: TextStyle(fontSize: 16, color: Colors.teal)),
                  Text(
                    '$_xp XP',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.teal,
              ),
              onPressed: () => context.go('/'),
              child: const Text('Tilbake til hjemskjermen', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
