import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

class TrueFalseWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const TrueFalseWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  String? _selected;
  bool _showingFeedback = false;
  bool _wasCorrect = false;

  void _handleAnswer(String option) {
    if (_showingFeedback) return;

    final isCorrect = option.toLowerCase() == widget.question.correctAnswer.toLowerCase();

    setState(() {
      _selected = option;
      _showingFeedback = true;
      _wasCorrect = isCorrect;
    });

    final delay = (widget.isPractice && !isCorrect) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(option);
    });
  }

  @override
  void didUpdateWidget(TrueFalseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _selected = null;
      _showingFeedback = false;
      _wasCorrect = false;
    }
  }

  Color _buttonColor(String option) {
    if (!_showingFeedback) {
      return option == 'Sant' ? Colors.green.shade700 : Colors.red.shade700;
    }
    if (option.toLowerCase() == widget.question.correctAnswer.toLowerCase()) {
      return Colors.green.shade600;
    }
    if (option == _selected) return Colors.red.shade600;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Sant eller usant?',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              widget.question.text,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _TFButton(
                label: 'Sant',
                icon: Icons.check_rounded,
                color: _buttonColor('Sant'),
                onPressed: _showingFeedback ? null : () => _handleAnswer('Sant'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TFButton(
                label: 'Usant',
                icon: Icons.close_rounded,
                color: _buttonColor('Usant'),
                onPressed: _showingFeedback ? null : () => _handleAnswer('Usant'),
              ),
            ),
          ],
        ),
        if (_showingFeedback && widget.isPractice) ...[
          const SizedBox(height: 16),
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.correctAnswer,
            explanation: widget.question.explanation,
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _TFButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 28),
        backgroundColor: color,
        disabledBackgroundColor: color,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: onPressed != null ? 6 : 2,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
