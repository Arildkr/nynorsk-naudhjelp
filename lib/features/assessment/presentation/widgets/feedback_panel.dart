import 'package:flutter/material.dart';

/// Inline feedback card shown after answering a question in practice mode.
/// Shows green + praise when correct, red + correct answer + explanation when wrong.
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isCorrect ? Colors.green.shade400 : Colors.red.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isCorrect
          ? Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Knallbra! Heilt rett!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Feil. Riktig svar: $correctAnswer',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          explanation,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 14,
                            height: 1.4,
                          ),
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
