// lib/features/assessment/presentation/assessment_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'assessment_controller.dart';
import '../models/question.dart';
import 'widgets/multiple_choice_widget.dart';
import 'widgets/swipe_choice_widget.dart';
import 'widgets/fill_in_widget.dart';
import 'widgets/true_false_widget.dart';
import 'widgets/matching_widget.dart';

class AssessmentFlowScreen extends ConsumerWidget {
  const AssessmentFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(assessmentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartlegging'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Feil oppsto: $err')),
        data: (state) {
          if (state.questions.isEmpty) {
            return const Center(child: Text('Fann ingen spørsmål i banken.'));
          }

          if (state.isCompleted) {
            return _buildResult(context, state);
          }

          final q = state.currentQuestion;
          final progress = (state.currentIndex) / state.questions.length;

          return SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey.shade300, color: Colors.deepPurple),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildQuestionWidget(context, ref, q),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, WidgetRef ref, Question q) {
    switch (q.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: q,
          onAnswered: (answer) => ref.read(assessmentControllerProvider.notifier).answerCurrentQuestion(answer),
        );
      case QuestionType.swipeChoice:
        return SwipeChoiceWidget(
          question: q,
          onAnswered: (answer) => ref.read(assessmentControllerProvider.notifier).answerCurrentQuestion(answer),
        );
      case QuestionType.fillIn:
        return FillInWidget(
          question: q,
          onAnswered: (answer) => ref.read(assessmentControllerProvider.notifier).answerCurrentQuestion(answer),
        );
      case QuestionType.trueOrFalse:
        return TrueFalseWidget(
          question: q,
          onAnswered: (answer) => ref.read(assessmentControllerProvider.notifier).answerCurrentQuestion(answer),
        );
      case QuestionType.matching:
        return MatchingWidget(
          question: q,
          onAnswered: (answer) => ref.read(assessmentControllerProvider.notifier).answerCurrentQuestion(answer),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, size: 120, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Flott jobba!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Text(
              'Du fekk $score av ${state.questions.length} rette. Me har lagra resultatet slik at me kan tilpasse oppgåvene dine framover.',
              style: const TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: () => context.go('/'),
              child: const Text('Tilbake til hjemskjermen', style: TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
