import 'package:flutter/material.dart';

/// Inline feedback card shown after answering a question in practice mode.
class FeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;

  const FeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isCorrect
        ? (isDark ? Colors.green.shade900.withOpacity(0.6) : Colors.green.shade50)
        : (isDark ? Colors.red.shade900.withOpacity(0.6) : Colors.red.shade50);
    final borderColor = isCorrect ? Colors.green.shade400 : Colors.red.shade400;
    final textColor = isDark ? Colors.white : (isCorrect ? Colors.green.shade900 : Colors.red.shade900);
    final subTextColor = isDark ? Colors.white70 : (isCorrect ? Colors.green.shade800 : Colors.red.shade800);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isCorrect
          ? Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Knallbra! Heilt rett!',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Feil. Riktig svar: $correctAnswer',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Colors.amber.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          explanation,
                          style: TextStyle(color: subTextColor, fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
