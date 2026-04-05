import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

class SwipeChoiceWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const SwipeChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<SwipeChoiceWidget> createState() => _SwipeChoiceWidgetState();
}

class _SwipeChoiceWidgetState extends State<SwipeChoiceWidget> {
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

    final delay = (widget.isPractice && !isCorrect) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(option);
    });
  }

  @override
  void didUpdateWidget(SwipeChoiceWidget oldWidget) {
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
        const SizedBox(height: 20),
        Text(
          widget.question.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: widget.question.options.map((opt) {
            Color chipColor = Colors.deepPurple;
            if (_showingFeedback) {
              if (opt.toLowerCase() == widget.question.correctAnswer.toLowerCase()) {
                chipColor = Colors.green.shade600;
              } else if (opt == _selectedOption) {
                chipColor = Colors.red.shade600;
              } else {
                chipColor = Colors.grey.shade400;
              }
            }

            return Material(
              color: chipColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showingFeedback ? null : () => _handleAnswer(opt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(opt, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        if (_showingFeedback && widget.isPractice)
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.correctAnswer,
            explanation: widget.question.explanation,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.touch_app, color: Colors.grey),
              SizedBox(width: 8),
              Text('Trykk på eit alternativ', style: TextStyle(color: Colors.grey)),
            ],
          ),
      ],
    );
  }
}
