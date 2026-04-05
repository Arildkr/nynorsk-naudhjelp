import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

/// Matching widget: venstrespalte = ord, høgrespalte = definisjonar.
/// Brukaren trykkjer på eitt frå kvar side for å kople dei saman.
/// Spørsmålet sitt `options`-felt inneheld alternativa på forma "Ord|Definisjon".
/// `correctAnswer` er det rette "Ord|Definisjon"-paret.
class MatchingWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const MatchingWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  String? _selectedLeft;
  final Map<String, String> _matched = {}; // ord → definisjon
  bool _showingFeedback = false;
  bool _wasCorrect = false;
  late List<String> _leftItems;
  late List<String> _rightItems;

  @override
  void initState() {
    super.initState();
    _buildLists();
  }

  void _buildLists() {
    _leftItems = widget.question.options.map((o) => o.split('|').first).toList();
    _rightItems = widget.question.options.map((o) => o.split('|').last).toList()..shuffle();
  }

  @override
  void didUpdateWidget(MatchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _selectedLeft = null;
      _matched.clear();
      _showingFeedback = false;
      _wasCorrect = false;
      _buildLists();
    }
  }

  void _onTapLeft(String word) {
    if (_showingFeedback || _matched.containsKey(word)) return;
    setState(() => _selectedLeft = word);
  }

  void _onTapRight(String definition) {
    if (_showingFeedback) return;
    if (_selectedLeft == null) return;
    if (_matched.values.contains(definition)) return;

    setState(() {
      _matched[_selectedLeft!] = definition;
      _selectedLeft = null;
    });

    if (_matched.length == _leftItems.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    // Riktig om alle par stemmer med options
    bool allCorrect = true;
    for (final opt in widget.question.options) {
      final parts = opt.split('|');
      if (parts.length != 2) continue;
      if (_matched[parts[0]] != parts[1]) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _showingFeedback = true;
      _wasCorrect = allCorrect;
    });

    final delay = (widget.isPractice && !allCorrect) ? 3000 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(allCorrect ? widget.question.correctAnswer : '');
    });
  }

  Color _leftColor(String word) {
    if (_showingFeedback) {
      final correct = widget.question.options.firstWhere((o) => o.startsWith('$word|'), orElse: () => '').split('|').last;
      return _matched[word] == correct ? Colors.green.shade600 : Colors.red.shade600;
    }
    if (word == _selectedLeft) return Colors.deepPurple;
    if (_matched.containsKey(word)) return Colors.teal.shade600;
    return Colors.deepPurple.shade200;
  }

  Color _rightColor(String def) {
    if (_showingFeedback) {
      final correctWord = widget.question.options.firstWhere((o) => o.endsWith('|$def'), orElse: () => '').split('|').first;
      return _matched[correctWord] == def ? Colors.green.shade600 : Colors.red.shade600;
    }
    if (_matched.values.contains(def)) return Colors.teal.shade600;
    if (_selectedLeft != null) return Colors.orange.shade300;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Kople saman ord og forklaring',
            style: TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.question.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Venstrespalte — ord
              Expanded(
                child: Column(
                  children: _leftItems.map((word) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _onTapLeft(word),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: _leftColor(word),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: word == _selectedLeft
                              ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 12),
              // Høgrespalte — definisjonar
              Expanded(
                child: Column(
                  children: _rightItems.map((def) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _onTapRight(def),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: _rightColor(def),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          def,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
        if (_showingFeedback && widget.isPractice)
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.options.join(', '),
            explanation: widget.question.explanation,
          ),
        if (!_showingFeedback)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _selectedLeft != null
                  ? 'Trykkjer du no på ei forklaring til høgre...'
                  : 'Trykk på eit ord, så ei forklaring',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
