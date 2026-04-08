import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _CardEntry {
  final String text;
  final bool isNynorsk;
  final String hint;
  const _CardEntry(this.text, this.isNynorsk, [this.hint = '']);
}

class SwipeClassifyScreen extends StatefulWidget {
  const SwipeClassifyScreen({super.key});

  @override
  State<SwipeClassifyScreen> createState() => _SwipeClassifyScreenState();
}

class _SwipeClassifyScreenState extends State<SwipeClassifyScreen>
    with TickerProviderStateMixin {
  // ── Card data ──────────────────────────────────────────────────────────────
  static const _allCards = [
    // Core vocabulary
    _CardEntry('ikkje', true, '"ikke" på bokmål'),
    _CardEntry('ikke', false, '"ikkje" på nynorsk'),
    _CardEntry('eg', true, '"jeg" på bokmål'),
    _CardEntry('jeg', false, '"eg" på nynorsk'),
    _CardEntry('kvifor', true, '"hvorfor" på bokmål'),
    _CardEntry('hvorfor', false, '"kvifor" på nynorsk'),
    _CardEntry('korleis', true, '"hvordan" på bokmål'),
    _CardEntry('hvordan', false, '"korleis" på nynorsk'),
    _CardEntry('kven', true, '"hvem" på bokmål'),
    _CardEntry('hvem', false, '"kven" på nynorsk'),
    _CardEntry('mykje', true, '"mye" på bokmål'),
    _CardEntry('mye', false, '"mykje" på nynorsk'),
    _CardEntry('berre', true, '"bare" på bokmål'),
    _CardEntry('bare', false, '"berre" på nynorsk'),
    _CardEntry('saman', true, '"sammen" på bokmål'),
    _CardEntry('sammen', false, '"saman" på nynorsk'),
    _CardEntry('sjølv', true, '"selv" på bokmål'),
    _CardEntry('selv', false, '"sjølv" på nynorsk'),
    _CardEntry('framleis', true, '"fremdeles" på bokmål'),
    _CardEntry('fremdeles', false, '"framleis" på nynorsk'),
    _CardEntry('nokon', true, '"noen" på bokmål'),
    _CardEntry('noen', false, '"nokon" på nynorsk'),
    _CardEntry('heim', true, '"hjem" på bokmål'),
    _CardEntry('hjem', false, '"heim" på nynorsk'),
    _CardEntry('stad', true, '"sted" på bokmål'),
    _CardEntry('sted', false, '"stad" på nynorsk'),
    _CardEntry('fleire', true, '"flere" på bokmål'),
    _CardEntry('flere', false, '"fleire" på nynorsk'),
    _CardEntry('dessutan', true, '"dessuten" på bokmål'),
    _CardEntry('dessuten', false, '"dessutan" på nynorsk'),
    _CardEntry('plutseleg', true, '"plutselig" på bokmål'),
    _CardEntry('plutselig', false, '"plutseleg" på nynorsk'),
    _CardEntry('utan', true, '"uten" på bokmål'),
    _CardEntry('uten', false, '"utan" på nynorsk'),
    _CardEntry('likevel', true, 'same på begge, men "allikevel" er bokmål'),
    _CardEntry('allikevel', false, '"likevel" på nynorsk'),
    // Verb forms
    _CardEntry('kastar', true, 'presens a-verb (kastar ≠ kaster)'),
    _CardEntry('kaster', false, '"kastar" på nynorsk'),
    _CardEntry('kasta', true, 'preteritum a-verb (kasta ≠ kastet)'),
    _CardEntry('kastet', false, '"kasta" på nynorsk'),
    _CardEntry('kjem', true, 'presens av "å kome"'),
    _CardEntry('kommer', false, '"kjem" på nynorsk'),
    _CardEntry('skreiv', true, 'preteritum av "å skrive"'),
    _CardEntry('skrev', false, '"skreiv" på nynorsk'),
    _CardEntry('syngjer', true, 'presens av "å syngje"'),
    _CardEntry('synger', false, '"syngjer" på nynorsk'),
    // Noun forms (definite)
    _CardEntry('boka', true, 'bestemt form hokjønn (boka ≠ boken)'),
    _CardEntry('boken', false, '"boka" på nynorsk'),
    _CardEntry('gutane', true, 'bestemt fleirtal hankjønn'),
    _CardEntry('guttene', false, '"gutane" på nynorsk'),
    _CardEntry('husa', true, 'bestemt fleirtal inkjekjønn'),
    _CardEntry('husene', false, '"husa" på nynorsk'),
    _CardEntry('elva', true, 'bestemt form hokjønn (elva ≠ elven)'),
    _CardEntry('elven', false, '"elva" på nynorsk'),
    _CardEntry('sola', true, 'bestemt form hokjønn'),
    _CardEntry('solen', false, '"sola" på nynorsk'),
  ];

  late List<_CardEntry> _deck;
  int _currentIdx = 0;
  double _dragX = 0;
  bool _isAnimating = false;
  int _correct = 0;
  int _total = 0;
  bool _lastWasCorrect = false;
  String _lastHint = '';

  late AnimationController _throwCtrl;
  late AnimationController _returnCtrl;
  late AnimationController _feedbackCtrl;
  bool _thrownRight = false;

  @override
  void initState() {
    super.initState();
    _deck = List.from(_allCards)..shuffle(Random());

    _throwCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onCardDismissed();
      });

    _returnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _dragX = 0;
            _isAnimating = false;
          });
        }
      });

    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _throwCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _throwCtrl.dispose();
    _returnCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _dragX += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isAnimating) return;
    final w = MediaQuery.of(context).size.width;
    if (_dragX.abs() > w * 0.33) {
      HapticFeedback.mediumImpact();
      _thrownRight = _dragX > 0;
      final swipedNynorsk = _thrownRight;
      final card = _deck[_currentIdx % _deck.length];
      final correct = swipedNynorsk == card.isNynorsk;
      setState(() {
        _total++;
        if (correct) _correct++;
        _lastWasCorrect = correct;
        _lastHint = card.isNynorsk
            ? (card.hint.isNotEmpty ? card.hint : 'Dette er nynorsk')
            : (card.hint.isNotEmpty ? card.hint : 'Dette er bokmål');
        _isAnimating = true;
      });
      _feedbackCtrl.forward(from: 0);
      _throwCtrl.forward(from: 0);
    } else {
      setState(() => _isAnimating = true);
      _returnCtrl.forward(from: 0);
    }
  }

  void _onCardDismissed() {
    setState(() {
      _currentIdx++;
      _dragX = 0;
      _isAnimating = false;
    });
    _throwCtrl.reset();
    if (_currentIdx >= _deck.length) {
      // reshuffle for replay
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentIdx >= _deck.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nynorsk eller bokmål?',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('$_correct / $_total',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
        ],
      ),
      body: isDone ? _buildResults() : _buildGame(context),
    );
  }

  Widget _buildGame(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final frac = (_dragX / (w * 0.45)).clamp(-1.0, 1.0);

    Color bg = Colors.black;
    if (frac > 0) {
      bg = Color.lerp(Colors.black, const Color(0xFF0D3B1A), frac)!;
    } else if (frac < 0) {
      bg = Color.lerp(Colors.black, const Color(0xFF3B0D0D), -frac)!;
    }

    final card = _deck[_currentIdx % _deck.length];

    return AnimatedContainer(
      duration: Duration.zero,
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Direction labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedOpacity(
                    opacity: frac < -0.08 ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 80),
                    child: Row(children: [
                      const Icon(Icons.arrow_back,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 4),
                      Text('Bokmål',
                          style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  AnimatedOpacity(
                    opacity: frac > 0.08 ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 80),
                    child: Row(children: [
                      Text('Nynorsk',
                          style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          color: Colors.greenAccent, size: 18),
                    ]),
                  ),
                ],
              ),
            ),

            // Feedback banner
            AnimatedBuilder(
              animation: _feedbackCtrl,
              builder: (ctx, _) {
                final t = _feedbackCtrl.value;
                final show = t > 0 && t < 1;
                if (!show) return const SizedBox.shrink();
                final opacity = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _lastWasCorrect
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _lastWasCorrect ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_lastHint,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Card stack
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 420,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back cards
                      if (_currentIdx + 2 < _deck.length)
                        _buildBackCard(
                            _deck[(_currentIdx + 2) % _deck.length],
                            -0.03,
                            const Offset(0, 16)),
                      if (_currentIdx + 1 < _deck.length)
                        _buildBackCard(
                            _deck[(_currentIdx + 1) % _deck.length],
                            0.02,
                            const Offset(0, 8)),
                      // Top card
                      GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: _buildTopCard(card, frac, w),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '${_deck.length - _currentIdx} kort att',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(_CardEntry card, double rot, Offset offset) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: rot,
        child: Container(
          width: 300,
          height: 380,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(_CardEntry card, double frac, double screenW) {
    double offsetX = _dragX;
    double rotation = _dragX / 380;

    if (_isAnimating && _throwCtrl.isAnimating) {
      final t = Curves.easeIn.transform(_throwCtrl.value);
      offsetX = _dragX + (_thrownRight ? 1 : -1) * screenW * 1.3 * t;
      rotation = _dragX / 380 + (_thrownRight ? 1 : -1) * 0.25 * t;
    } else if (_isAnimating && _returnCtrl.isAnimating) {
      final t = Curves.easeOut.transform(_returnCtrl.value);
      offsetX = _dragX * (1 - t);
      rotation = (_dragX / 380) * (1 - t);
    }

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.rotate(
        angle: rotation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Card body
            Container(
              width: 300,
              height: 380,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 24,
                      spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    card.text,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Nynorsk stamp (right drag)
            if (frac > 0.05)
              Positioned(
                top: 40,
                right: 20,
                child: Opacity(
                  opacity: frac.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: 0.35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.greenAccent, width: 3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('NYNORSK',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),

            // Bokmål stamp (left drag)
            if (frac < -0.05)
              Positioned(
                top: 40,
                left: 20,
                child: Opacity(
                  opacity: (-frac).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.redAccent, width: 3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BOKMÅL',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final pct = _total > 0 ? _correct / _total : 0.0;
    final col = pct >= 0.8
        ? Colors.greenAccent
        : pct >= 0.5
            ? Colors.orange
            : Colors.redAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pct >= 0.8 ? '🎉' : pct >= 0.5 ? '👍' : '📚',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 20),
            Text('$_correct / $_total rette',
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('${(pct * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 22,
                    color: col,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                setState(() {
                  _deck = List.from(_allCards)..shuffle(Random());
                  _currentIdx = 0;
                  _correct = 0;
                  _total = 0;
                  _dragX = 0;
                  _isAnimating = false;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Spel igjen',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
