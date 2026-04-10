import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/question.dart';
import 'feedback_panel.dart';

/// Laser-line matching widget.
///
/// options format:
///   "bokmål|nynorsk"   → real pair (shows in both columns)
///   "_|decoy"          → right-column-only decoy
///
/// correctAnswer: "bokmål|nynorsk,bokmål2|nynorsk2,..." (all correct pairs)
///
/// User drags from a left item to a right item to connect them.
/// When all left items are connected → auto-checks.
class LaserMatchWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswered;
  final bool isPractice;

  const LaserMatchWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.isPractice = false,
  });

  @override
  State<LaserMatchWidget> createState() => _LaserMatchWidgetState();
}

class _LaserMatchWidgetState extends State<LaserMatchWidget> {
  late List<String> _leftItems;
  late List<String> _rightItems;
  late Map<String, String> _correctPairs; // bokmål → nynorsk

  final Map<String, String> _matched = {}; // bokmål → nynorsk (user's choices)
  String? _selectedLeft;
  Offset? _dragStart;
  Offset? _dragCurrent;
  double _totalW = 0;
  double _totalH = 0;
  bool _showingFeedback = false;
  bool _wasCorrect = false;
  // Per-connection correctness (set when all done)
  Map<String, bool> _connectionCorrect = {};

  static const double _itemH = 58.0;
  static const double _topPad = 12.0;

  @override
  void initState() {
    super.initState();
    _buildLists();
  }

  void _buildLists() {
    final opts = widget.question.options;
    _correctPairs = {};
    final rightPool = <String>[];

    for (final o in opts) {
      final parts = o.split('|');
      if (parts.length != 2) continue;
      final left = parts[0];
      final right = parts[1];
      rightPool.add(right);
      if (left != '_') _correctPairs[left] = right;
    }

    _leftItems = _correctPairs.keys.toList();
    _rightItems = rightPool..shuffle(Random());
  }

  @override
  void didUpdateWidget(LaserMatchWidget old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _matched.clear();
      _connectionCorrect.clear();
      _selectedLeft = null;
      _dragStart = null;
      _dragCurrent = null;
      _showingFeedback = false;
      _wasCorrect = false;
      _buildLists();
    }
  }

  // ── Position helpers ─────────────────────────────────────────────────────────

  double _leftCX() => _totalW * 0.25;
  double _rightCX() => _totalW * 0.75;
  double _itemCY(int i) => _topPad + i * _itemH + _itemH / 2;

  int? _hitLeft(Offset pos) {
    if (pos.dx > _totalW / 2) return null;
    for (int i = 0; i < _leftItems.length; i++) {
      if ((pos.dy - _itemCY(i)).abs() < _itemH / 2) return i;
    }
    return null;
  }

  int? _hitRight(Offset pos) {
    if (pos.dx < _totalW / 2) return null;
    for (int i = 0; i < _rightItems.length; i++) {
      if ((pos.dy - _itemCY(i)).abs() < _itemH / 2) return i;
    }
    return null;
  }

  // ── Drag handlers ────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_showingFeedback) return;
    final li = _hitLeft(d.localPosition);
    if (li == null) return;
    final word = _leftItems[li];
    if (_matched.containsKey(word)) {
      // Allow re-connecting: remove existing match
      setState(() {
        _matched.remove(word);
        _connectionCorrect.remove(word);
      });
    }
    setState(() {
      _selectedLeft = word;
      _dragStart = Offset(_leftCX(), _itemCY(li));
      _dragCurrent = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_selectedLeft == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onPanEnd(DragEndDetails d) {
    final sel = _selectedLeft;
    if (sel == null) {
      _clearDrag();
      return;
    }
    final cur = _dragCurrent;
    if (cur != null) {
      final ri = _hitRight(cur);
      if (ri != null) {
        final rightWord = _rightItems[ri];
        // Disallow connecting two lefts to same right
        if (!_matched.values.contains(rightWord)) {
          HapticFeedback.selectionClick();
          setState(() => _matched[sel] = rightWord);
          if (_matched.length == _leftItems.length) {
            _checkAnswer();
            return;
          }
        }
      }
    }
    _clearDrag();
  }

  void _clearDrag() {
    setState(() {
      _selectedLeft = null;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _checkAnswer() {
    bool allCorrect = true;
    final connectionCorrect = <String, bool>{};
    for (final entry in _matched.entries) {
      final correct = _correctPairs[entry.key] == entry.value;
      connectionCorrect[entry.key] = correct;
      if (!correct) allCorrect = false;
    }
    setState(() {
      _connectionCorrect = connectionCorrect;
      _showingFeedback = true;
      _wasCorrect = allCorrect;
      _selectedLeft = null;
      _dragStart = null;
      _dragCurrent = null;
    });
    final delay = (widget.isPractice && !allCorrect) ? 3200 : 1600;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        widget.onAnswered(allCorrect ? widget.question.correctAnswer : '');
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction chip
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Dra ei line frå bokmålsordet til det nynorske',
            style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        // Question text
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            widget.question.text,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        // Matching area
        Expanded(
          child: LayoutBuilder(builder: (ctx, box) {
            _totalW = box.maxWidth;
            _totalH = box.maxHeight;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                children: [
                  // Items
                  _buildItems(),
                  // Lines
                  CustomPaint(
                    size: Size(_totalW, _totalH),
                    painter: _LaserPainter(
                      matched: _matched,
                      connectionCorrect: _connectionCorrect,
                      leftItems: _leftItems,
                      rightItems: _rightItems,
                      selectedLeft: _selectedLeft,
                      dragStart: _dragStart,
                      dragCurrent: _dragCurrent,
                      leftCX: _leftCX(),
                      rightCX: _rightCX(),
                      itemCY: _itemCY,
                      showingFeedback: _showingFeedback,
                    ),
                  ),
                  // Overlay columns (pointer-transparent — lines are on top)
                ],
              ),
            );
          }),
        ),
        if (_showingFeedback && widget.isPractice)
          FeedbackPanel(
            isCorrect: _wasCorrect,
            correctAnswer: _correctPairs.entries
                .map((e) => '${e.key} → ${e.value}')
                .join(', '),
            explanation: widget.question.explanation,
          ),
        if (!_showingFeedback)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _selectedLeft != null
                  ? 'Dra til eit ord i høgre kolonne...'
                  : _matched.length < _leftItems.length
                      ? 'Dra frå eit ord til venstre'
                      : 'Kople alle orda for å sjekke',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildItems() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topPad),
              for (int i = 0; i < _leftItems.length; i++)
                _leftChip(_leftItems[i], i),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topPad),
              for (int i = 0; i < _rightItems.length; i++)
                _rightChip(_rightItems[i], i),
            ],
          ),
        ),
      ],
    );
  }

  Color _leftColor(String word) {
    if (_showingFeedback) {
      final correct = _connectionCorrect[word] ?? false;
      return correct ? Colors.green.shade600 : Colors.red.shade600;
    }
    if (word == _selectedLeft) return Colors.deepPurple;
    if (_matched.containsKey(word)) return Colors.teal.shade600;
    return Colors.deepPurple.shade300;
  }

  Color _rightColor(String word) {
    if (_showingFeedback) {
      // find which left maps to this right
      final leftWord = _matched.entries
          .where((e) => e.value == word)
          .map((e) => e.key)
          .firstOrNull;
      if (leftWord == null) return Colors.grey.shade400; // unmatched decoy
      final correct = _connectionCorrect[leftWord] ?? false;
      return correct ? Colors.green.shade600 : Colors.red.shade600;
    }
    if (_matched.values.contains(word)) return Colors.teal.shade600;
    if (_selectedLeft != null) return Colors.orange.shade300;
    return Colors.grey.shade400;
  }

  Widget _leftChip(String word, int i) {
    return SizedBox(
      height: _itemH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _leftColor(word),
            borderRadius: BorderRadius.circular(14),
            boxShadow: word == _selectedLeft
                ? [
                    BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 8)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(word,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _rightChip(String word, int i) {
    return SizedBox(
      height: _itemH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _rightColor(word),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(word,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// ── Laser painter ─────────────────────────────────────────────────────────────

class _LaserPainter extends CustomPainter {
  final Map<String, String> matched;
  final Map<String, bool> connectionCorrect;
  final List<String> leftItems;
  final List<String> rightItems;
  final String? selectedLeft;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final double leftCX;
  final double rightCX;
  final double Function(int) itemCY;
  final bool showingFeedback;

  const _LaserPainter({
    required this.matched,
    required this.connectionCorrect,
    required this.leftItems,
    required this.rightItems,
    required this.selectedLeft,
    required this.dragStart,
    required this.dragCurrent,
    required this.leftCX,
    required this.rightCX,
    required this.itemCY,
    required this.showingFeedback,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed connections
    for (final entry in matched.entries) {
      final li = leftItems.indexOf(entry.key);
      final ri = rightItems.indexOf(entry.value);
      if (li < 0 || ri < 0) continue;

      final Color lineColor;
      if (showingFeedback) {
        lineColor = (connectionCorrect[entry.key] ?? false)
            ? Colors.green.shade400
            : Colors.red.shade400;
      } else {
        lineColor = Colors.teal.shade300;
      }

      _drawLaserLine(
        canvas,
        Offset(leftCX + 50, itemCY(li)),
        Offset(rightCX - 50, itemCY(ri)),
        lineColor,
        glow: !showingFeedback,
      );
    }

    // Draw live drag line
    if (selectedLeft != null && dragStart != null && dragCurrent != null) {
      final li = leftItems.indexOf(selectedLeft!);
      if (li >= 0) {
        _drawLaserLine(
          canvas,
          Offset(leftCX + 50, itemCY(li)),
          dragCurrent!,
          Colors.deepPurpleAccent.shade100,
          glow: true,
          dashed: true,
        );
      }
    }
  }

  void _drawLaserLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, {
    bool glow = false,
    bool dashed = false,
  }) {
    if (dashed) {
      // Dashed line for live drag
      final paint = Paint()
        ..color = color.withOpacity(0.75)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len == 0) return;
      const dashLen = 10.0;
      const gapLen = 6.0;
      double drawn = 0;
      Offset cur = from;
      bool drawing = true;
      while (drawn < len) {
        final seg = drawing ? dashLen : gapLen;
        final end = min(drawn + seg, len);
        final t = end / len;
        final next = Offset(from.dx + dx * t, from.dy + dy * t);
        if (drawing) canvas.drawLine(cur, next, paint);
        cur = next;
        drawn = end;
        drawing = !drawing;
      }
      return;
    }

    // Glow: draw thick dim + thin bright
    if (glow) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, glowPaint);
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, linePaint);
  }

  @override
  bool shouldRepaint(_LaserPainter old) =>
      old.matched != matched ||
      old.dragCurrent != dragCurrent ||
      old.selectedLeft != selectedLeft ||
      old.showingFeedback != showingFeedback;
}
