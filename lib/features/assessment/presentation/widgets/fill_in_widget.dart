import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

class FillInWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const FillInWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<FillInWidget> createState() => _FillInWidgetState();
}

class _FillInWidgetState extends State<FillInWidget> {
  final _controller = TextEditingController();
  bool _showingFeedback = false;
  bool _wasCorrect = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FillInWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _controller.clear();
      _showingFeedback = false;
      _wasCorrect = false;
    }
  }

  void _submit() {
    if (_showingFeedback) return;

    final answer = _controller.text.trim();
    if (answer.isEmpty) return;

    final isCorrect = answer.toLowerCase() == widget.question.correctAnswer.toLowerCase();

    setState(() {
      _showingFeedback = true;
      _wasCorrect = isCorrect;
    });

    final delay = (widget.isPractice && !isCorrect) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(answer);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.deepPurple;
    if (_showingFeedback) {
      borderColor = _wasCorrect ? Colors.green.shade600 : Colors.red.shade600;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.question.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _controller,
          enabled: !_showingFeedback,
          decoration: InputDecoration(
            hintText: 'Skriv inn ordet her...',
            filled: true,
            fillColor: _showingFeedback ? borderColor.withOpacity(0.1) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: _showingFeedback ? 3 : 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: _showingFeedback ? 3 : 1),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: _showingFeedback ? borderColor : Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Svar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        if (_showingFeedback && widget.isPractice) ...[
          const SizedBox(height: 8),
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.correctAnswer,
            explanation: widget.question.explanation,
          ),
        ],
      ],
    );
  }
}
