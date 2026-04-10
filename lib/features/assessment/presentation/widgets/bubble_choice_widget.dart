import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

/// Floating bubble choice: options drift up/down, tap the correct one to pop it.
class BubbleChoiceWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const BubbleChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<BubbleChoiceWidget> createState() => _BubbleChoiceWidgetState();
}

class _BubbleChoiceWidgetState extends State<BubbleChoiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late List<String> _shuffledOptions;
  late List<double> _phases;
  late List<double> _amplitudes;
  String? _selected;
  bool _showingFeedback = false;
  bool _wasCorrect = false;

  static const _colors = [
    Color(0xFF6D28D9), // violet
    Color(0xFF0369A1), // blue
    Color(0xFFBE185D), // pink
    Color(0xFFB45309), // amber
    Color(0xFF047857), // emerald
  ];

  // 5 base positions (fractions of area); first 4 for typical MC
  static const _basePos = [
    Offset(0.15, 0.22),
    Offset(0.58, 0.18),
    Offset(0.12, 0.65),
    Offset(0.60, 0.62),
    Offset(0.36, 0.40),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _init(Random());
  }

  void _init(Random rng) {
    _shuffledOptions = List.from(widget.question.options)..shuffle(rng);
    _phases = [for (int i = 0; i < _shuffledOptions.length; i++) rng.nextDouble() * 2 * pi];
    _amplitudes = [for (int i = 0; i < _shuffledOptions.length; i++) 9.0 + rng.nextDouble() * 11];
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BubbleChoiceWidget old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _init(Random());
      _selected = null;
      _showingFeedback = false;
      _wasCorrect = false;
    }
  }

  void _handleTap(String option) {
    if (_showingFeedback) return;
    final correct = option.toLowerCase() == widget.question.correctAnswer.toLowerCase();
    setState(() {
      _selected = option;
      _showingFeedback = true;
      _wasCorrect = correct;
    });
    final delay = (widget.isPractice && !correct) ? 2800 : 1400;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) widget.onAnswered(option);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.question.text,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _floatCtrl,
            builder: (ctx, _) {
              final t = _floatCtrl.value * 2 * pi;
              return LayoutBuilder(builder: (ctx, box) {
                final w = box.maxWidth;
                final h = box.maxHeight;
                return Stack(
                  children: [
                    for (int i = 0; i < _shuffledOptions.length; i++)
                      _bubble(
                        _shuffledOptions[i],
                        Offset(
                          _basePos[i % _basePos.length].dx * w,
                          _basePos[i % _basePos.length].dy * h +
                              sin(t + _phases[i]) * _amplitudes[i],
                        ),
                        i,
                        w,
                        h,
                      ),
                  ],
                );
              });
            },
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
            child: Text('Trykk på rett boble',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _bubble(String text, Offset center, int i, double maxW, double maxH) {
    final isCorrect = text.toLowerCase() == widget.question.correctAnswer.toLowerCase();
    final isSelected = text == _selected;
    final baseColor = _colors[i % _colors.length];

    Color color;
    double opacity = 1.0;
    if (_showingFeedback) {
      if (isCorrect) {
        color = Colors.green.shade600;
      } else if (isSelected) {
        color = Colors.red.shade600;
      } else {
        color = Colors.grey.shade400;
        opacity = 0.35;
      }
    } else {
      color = baseColor;
    }

    final bubW = (100.0 + text.length * 10).clamp(110.0, 210.0);
    const bubH = 68.0;
    final left = (center.dx - bubW / 2).clamp(0.0, maxW - bubW);
    final top = (center.dy - bubH / 2).clamp(0.0, maxH - bubH);

    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: GestureDetector(
          onTap: () => _handleTap(text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: bubW,
            height: bubH,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(_showingFeedback ? 0.2 : 0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
