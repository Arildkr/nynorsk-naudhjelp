import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

/// Tile-based conjugation widget.
/// options[0] = word stem, e.g. "kast-" (trailing dash = strip it)
/// options[1..n] = ending tiles, e.g. "-ar", "-a", "-et", "-"
/// correctAnswer = full inflected form, e.g. "kastar"
///
/// The "-" tile means no ending (stem = full form).
class TileChoiceWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const TileChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<TileChoiceWidget> createState() => _TileChoiceWidgetState();
}

class _TileChoiceWidgetState extends State<TileChoiceWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedEnding;
  bool _showingFeedback = false;
  bool _wasCorrect = false;
  late AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  String get _stemRaw => widget.question.options.isNotEmpty ? widget.question.options[0] : '';
  String get _stemDisplay =>
      _stemRaw.endsWith('-') ? _stemRaw.substring(0, _stemRaw.length - 1) : _stemRaw;
  List<String> get _endings =>
      widget.question.options.length > 1 ? widget.question.options.sublist(1) : [];

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _snapAnim = CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TileChoiceWidget old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _selectedEnding = null;
      _showingFeedback = false;
      _wasCorrect = false;
    }
  }

  String _buildWord(String ending) {
    if (ending == '-') return _stemDisplay;
    final suf = ending.startsWith('-') ? ending.substring(1) : ending;
    return '$_stemDisplay$suf';
  }

  bool _isCorrectEnding(String ending) =>
      _buildWord(ending).toLowerCase() == widget.question.correctAnswer.toLowerCase();

  void _handleSelect(String ending) {
    if (_showingFeedback) return;
    HapticFeedback.lightImpact();
    final correct = _isCorrectEnding(ending);
    setState(() {
      _selectedEnding = ending;
      _showingFeedback = true;
      _wasCorrect = correct;
    });
    _snapCtrl.forward(from: 0);
    final delay = (widget.isPractice && !correct) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(_buildWord(ending));
    });
  }

  Color _tileColor(String ending) {
    if (!_showingFeedback) return const Color(0xFF6D28D9);
    if (_isCorrectEnding(ending)) return Colors.green.shade600;
    if (ending == _selectedEnding) return Colors.red.shade600;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final answerColor = _showingFeedback
        ? (_wasCorrect ? Colors.green.shade600 : Colors.red.shade600)
        : const Color(0xFF6D28D9);

    // What to show as the ending in the display slot
    final endingDisplay = _selectedEnding == null
        ? null
        : (_selectedEnding == '-' ? '' : _selectedEnding!.substring(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question text
        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.question.text,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Word display: stem chip + ending slot
        Expanded(
          flex: 3,
          child: Center(
            child: AnimatedBuilder(
              animation: _snapAnim,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: answerColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: answerColor.withOpacity(0.45), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // Stem — fixed
                    Text(
                      _stemDisplay,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Ending — animates in
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween(begin: 0.4, end: 1.0).animate(
                            CurvedAnimation(
                                parent: anim, curve: Curves.elasticOut)),
                        child: child,
                      ),
                      child: Text(
                        endingDisplay ?? '___',
                        key: ValueKey(endingDisplay),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: answerColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tile pool
        Expanded(
          flex: 4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _endings.map(_buildTile).toList(),
              ),
            ),
          ),
        ),

        if (_showingFeedback && widget.isPractice)
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: widget.question.correctAnswer,
            explanation: widget.question.explanation,
          ),
        if (!_showingFeedback)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Trykk på rett ending',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildTile(String ending) {
    final color = _tileColor(ending);
    final dimmed = _showingFeedback &&
        ending != _selectedEnding &&
        !_isCorrectEnding(ending);

    return GestureDetector(
      onTap: () => _handleSelect(ending),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: dimmed
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          ending,
          style: TextStyle(
            color: dimmed ? Colors.white54 : Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
