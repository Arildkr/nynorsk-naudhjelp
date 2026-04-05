import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selectedOption;
  bool _showingFeedback = false;
  bool _wasCorrect = false;

  void _handleAnswer(String option) {
    if (_showingFeedback) return;

    final isCorrect = option.toLowerCase() == widget.question.correctAnswer.toLowerCase();

    setState(() {
      _selectedOption = option;
      _showingFeedback = true;
      _wasCorrect = isCorrect;
    });

    // Give extra time to read the explanation when wrong in practice mode
    final delay = (widget.isPractice && !isCorrect) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(option);
    });
  }

  @override
  void didUpdateWidget(MultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _selectedOption = null;
      _showingFeedback = false;
      _wasCorrect = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              widget.question.text,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ListView.separated(
            itemCount: widget.question.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final option = widget.question.options[index];
              Color buttonColor = Colors.deepPurple;

              if (_showingFeedback) {
                if (option.toLowerCase() == widget.question.correctAnswer.toLowerCase()) {
                  buttonColor = Colors.green.shade600;
                } else if (option == _selectedOption) {
                  buttonColor = Colors.red.shade600;
                } else {
                  buttonColor = Colors.grey.shade400;
                }
              }

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: buttonColor,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: _showingFeedback ? 2 : 6,
                ),
                onPressed: _showingFeedback ? null : () => _handleAnswer(option),
                child: Text(option, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
        if (_showingFeedback && widget.isPractice)
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.correctAnswer,
            explanation: widget.question.explanation,
          ),
      ],
    );
  }
}
