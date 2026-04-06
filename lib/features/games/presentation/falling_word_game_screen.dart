import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class _WordData {
  final String word;
  final String cat;
  /// For verbs: conjugation hint shown on wrong answer, e.g. "kastar / kasta".
  /// For nouns: leave empty — article is derived from zone hint at runtime.
  final String note;
  const _WordData(this.word, this.cat, [this.note = '']);
}

class _ZoneData {
  final String id;
  final String label;
  final String hint;
  final Color color;
  final IconData icon;
  const _ZoneData(this.id, this.label, this.hint, this.color, this.icon);
}

class FallingWordGameScreen extends StatefulWidget {
  /// 'kjonn' for gender game, 'verb' for verb-type game
  final String gameType;
  const FallingWordGameScreen({super.key, required this.gameType});

  @override
  State<FallingWordGameScreen> createState() => _FallingWordGameScreenState();
}

class _FallingWordGameScreenState extends State<FallingWordGameScreen>
    with TickerProviderStateMixin {
  // ── Word data ─────────────────────────────────────────────────────────────
  static const _kjonWords = [
    _WordData('bil', 'hankjonn'),
    _WordData('båt', 'hankjonn'),
    _WordData('hund', 'hankjonn'),
    _WordData('dag', 'hankjonn'),
    _WordData('fjord', 'hankjonn'),
    _WordData('fisk', 'hankjonn'),
    _WordData('gut', 'hankjonn'),
    _WordData('arm', 'hankjonn'),
    _WordData('skule', 'hankjonn'),
    _WordData('ring', 'hankjonn'),
    _WordData('sang', 'hankjonn'),
    _WordData('veg', 'hankjonn'),
    _WordData('stein', 'hankjonn'),
    _WordData('bror', 'hankjonn'),
    _WordData('son', 'hankjonn'),
    _WordData('bok', 'hokjonn'),
    _WordData('hand', 'hokjonn'),
    _WordData('sol', 'hokjonn'),
    _WordData('grein', 'hokjonn'),
    _WordData('jente', 'hokjonn'),
    _WordData('gate', 'hokjonn'),
    _WordData('dør', 'hokjonn'),
    _WordData('bru', 'hokjonn'),
    _WordData('natt', 'hokjonn'),
    _WordData('jord', 'hokjonn'),
    _WordData('seng', 'hokjonn'),
    _WordData('tid', 'hokjonn'),
    _WordData('ku', 'hokjonn'),
    _WordData('hylle', 'hokjonn'),
    _WordData('lampe', 'hokjonn'),
    _WordData('hus', 'inkjekjonn'),
    _WordData('barn', 'inkjekjonn'),
    _WordData('bord', 'inkjekjonn'),
    _WordData('tre', 'inkjekjonn'),
    _WordData('skip', 'inkjekjonn'),
    _WordData('fjell', 'inkjekjonn'),
    _WordData('egg', 'inkjekjonn'),
    _WordData('brød', 'inkjekjonn'),
    _WordData('glas', 'inkjekjonn'),
    _WordData('kart', 'inkjekjonn'),
    _WordData('lys', 'inkjekjonn'),
    _WordData('hav', 'inkjekjonn'),
    _WordData('hjarte', 'inkjekjonn'),
    _WordData('land', 'inkjekjonn'),
    _WordData('stykke', 'inkjekjonn'),
  ];

  static const _verbWords = [
    // ── A-verb (presens -ar, preteritum -a) ──────────────────────────────────
    _WordData('kaste', 'averb', 'kastar / kasta'),
    _WordData('hoppe', 'averb', 'hoppar / hoppa'),
    _WordData('snakke', 'averb', 'snakkar / snakka'),
    _WordData('elske', 'averb', 'elskar / elska'),
    _WordData('lage', 'averb', 'lagar / laga'),
    _WordData('rope', 'averb', 'ropar / ropa'),
    _WordData('jobbe', 'averb', 'jobbar / jobba'),
    _WordData('leike', 'averb', 'leikar / leika'),
    _WordData('handle', 'averb', 'handlar / handla'),
    _WordData('male', 'averb', 'malar / mala'),
    _WordData('starte', 'averb', 'startar / starta'),
    _WordData('lande', 'averb', 'landar / landa'),
    // ── E-verb (presens -er, preteritum -te/-de) ─────────────────────────────
    _WordData('lyse', 'everb', 'lyser / lyste'),
    _WordData('løyse', 'everb', 'løyser / løyste'),
    _WordData('selje', 'everb', 'sel / selde'),
    _WordData('velje', 'everb', 'vel / valde'),
    _WordData('gøyme', 'everb', 'gøymer / gøymde'),
    _WordData('tene', 'everb', 'tener / tente'),
    _WordData('smile', 'everb', 'smiler / smilte'),
    _WordData('hjelpe', 'everb', 'hjelper / hjelpte'),
    // ── Sterke verb (uregelmessig preteritum) ─────────────────────────────────
    _WordData('ta', 'sterk', 'tek / tok'),
    _WordData('sjå', 'sterk', 'ser / såg'),
    _WordData('gå', 'sterk', 'går / gjekk'),
    _WordData('bite', 'sterk', 'bit / beit'),
    _WordData('finne', 'sterk', 'finn / fann'),
    _WordData('kome', 'sterk', 'kjem / kom'),
    _WordData('sove', 'sterk', 'søv / sov'),
    _WordData('nyte', 'sterk', 'nyt / naut'),
    _WordData('stige', 'sterk', 'stig / steig'),
    _WordData('skrive', 'sterk', 'skriv / skreiv'),
  ];

  // ── Zone / category config ─────────────────────────────────────────────────
  late final List<_ZoneData> _zones;
  late final String _gameTitle;

  // ── Game state ─────────────────────────────────────────────────────────────
  int _lives = 3;
  int _score = 0;
  int _level = 1;
  int _correctCount = 0;
  bool _feedbackVisible = false;
  bool _lastCorrect = false;
  String? _pickedZoneId;
  bool _gameOver = false;
  double _fallDuration = 5.2;

  // ── Word queue ─────────────────────────────────────────────────────────────
  late List<_WordData> _bag;
  _WordData? _current;
  // Seed explicitly from clock so each game session gets a unique sequence.
  final Random _rng = Random(DateTime.now().microsecondsSinceEpoch);

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _fallCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _scorePopCtrl;
  late final Animation<double> _scorePopSlide;
  int _scorePopVal = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    if (widget.gameType == 'kjonn') {
      _gameTitle = 'Kva kjønn har substantivet?';
      _zones = const [
        _ZoneData('hankjonn', 'Hankjønn', 'ein', Color(0xFF2979FF), Icons.man_rounded),
        _ZoneData('hokjonn', 'Hokjønn', 'ei', Color(0xFFE91E8B), Icons.woman_rounded),
        _ZoneData('inkjekjonn', 'Inkjekjønn', 'eit', Color(0xFF2E7D32), Icons.all_inclusive_rounded),
      ];
    } else {
      _gameTitle = 'Kva type verb?';
      _zones = const [
        _ZoneData('averb', 'A-verb', '–a', Color(0xFFE65100), Icons.looks_one_rounded),
        _ZoneData('everb', 'E-verb', '–te', Color(0xFF6A1B9A), Icons.looks_two_rounded),
        _ZoneData('sterk', 'Sterkt verb', 'uregelmessig', Color(0xFF00695C), Icons.flash_on_rounded),
      ];
    }

    _fallCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_fallDuration * 1000).round()),
    )..addStatusListener(_onFallStatus);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _scorePopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scorePopSlide = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _scorePopCtrl, curve: Curves.easeOut),
    );

    _refillBag();
    _nextWord();
  }

  @override
  void dispose() {
    _fallCtrl.dispose();
    _shakeCtrl.dispose();
    _scorePopCtrl.dispose();
    super.dispose();
  }

  // ── Game logic ─────────────────────────────────────────────────────────────
  void _refillBag() {
    _bag = List.of(widget.gameType == 'kjonn' ? _kjonWords : _verbWords)
      ..shuffle(_rng);
  }

  void _nextWord() {
    if (_gameOver) return;
    if (_bag.isEmpty) _refillBag();
    setState(() {
      _current = _bag.removeLast();
      _feedbackVisible = false;
      _pickedZoneId = null;
    });
    _fallCtrl
      ..duration = Duration(milliseconds: (_fallDuration * 1000).round())
      ..forward(from: 0);
  }

  void _onFallStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _feedbackVisible) return;
    _handleAnswer(null); // missed
  }

  void _handleAnswer(String? pickedId) {
    if (_feedbackVisible || _gameOver || _current == null) return;
    _fallCtrl.stop();

    final correct = pickedId != null && pickedId == _current!.cat;

    if (correct) {
      final pts = 10 + _level * 2;
      _scorePopVal = pts;
      setState(() => _score += pts);
      _scorePopCtrl.forward(from: 0);
      _correctCount++;
      HapticFeedback.lightImpact();
      if (_correctCount % 5 == 0) {
        _level++;
        _fallDuration = (_fallDuration - 0.45).clamp(1.4, 99.0);
      }
    } else {
      setState(() => _lives--);
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
    }

    setState(() {
      _feedbackVisible = true;
      _lastCorrect = correct;
      _pickedZoneId = pickedId;
    });

    final delay = correct ? 700 : 1100;
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      if (_lives <= 0) {
        setState(() => _gameOver = true);
      } else {
        _nextWord();
      }
    });
  }

  void _restart() {
    setState(() {
      _lives = 3;
      _score = 0;
      _level = 1;
      _correctCount = 0;
      _gameOver = false;
      _feedbackVisible = false;
      _pickedZoneId = null;
      _fallDuration = 5.2;
    });
    _refillBag();
    _nextWord();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──
          _buildBackground(),
          SafeArea(
            child: _gameOver ? _buildGameOver() : _buildGame(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0225), Color(0xFF0B1B5C), Color(0xFF072A4A)],
        ),
      ),
      child: CustomPaint(painter: _StarsPainter()),
    );
  }

  Widget _buildGame() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _buildHud(),
            Expanded(child: _buildFallArea()),
            _buildFeedbackBanner(),
            _buildZones(),
          ],
        ),
        // Score pop overlay
        AnimatedBuilder(
          animation: _scorePopCtrl,
          builder: (_, __) {
            if (_scorePopCtrl.value == 0 && !_scorePopCtrl.isAnimating) {
              return const SizedBox.shrink();
            }
            final opacity = (1.0 - _scorePopCtrl.value * 1.6).clamp(0.0, 1.0);
            return Positioned(
              top: 50 + _scorePopSlide.value,
              right: 20,
              child: Opacity(
                opacity: opacity,
                child: Text(
                  '+$_scorePopVal',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Back button
          _hudIcon(Icons.close_rounded, () => context.go('/practice')),
          const SizedBox(width: 6),
          // Score
          _hudChip(Icons.star_rounded, Colors.amber, '$_score'),
          const SizedBox(width: 6),
          // Level
          _hudChip(Icons.trending_up_rounded, Colors.lightBlueAccent, 'Nivå $_level'),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _gameTitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Lives
          Row(
            children: List.generate(3, (i) {
              final alive = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    key: ValueKey('$i$alive'),
                    alive ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                    color: alive ? Colors.red.shade400 : Colors.white24,
                    size: 27,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(IconData icon, Color iconColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _hudIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ── Fall area ──────────────────────────────────────────────────────────────
  Widget _buildFallArea() {
    return AnimatedBuilder(
      animation: _fallCtrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const cardH = 78.0;
            final maxY = constraints.maxHeight - cardH;
            final y = _fallCtrl.value * maxY;
            final progress = maxY > 0 ? y / maxY : 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Speed / progress indicator strip on left
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _fallCtrl.value,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        progress > 0.75
                            ? Colors.red.shade400
                            : progress > 0.5
                                ? Colors.orange.shade400
                                : Colors.green.shade400,
                      ),
                    ),
                  ),
                ),
                // Word card
                if (_current != null)
                  Positioned(
                    top: y,
                    left: 18,
                    right: 18,
                    height: cardH,
                    child: AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: _buildWordCard(progress),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWordCard(double progress) {
    late Color bg;
    late Color fg;

    if (_feedbackVisible) {
      bg = _lastCorrect ? Colors.green.shade400 : Colors.red.shade400;
      fg = Colors.white;
    } else {
      // Card shifts from white to warm orange near the bottom (danger zone)
      final t = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      bg = Color.lerp(Colors.white, Colors.orange.shade200, t)!;
      fg = const Color(0xFF0D0225);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (_feedbackVisible
                    ? (_lastCorrect ? Colors.green : Colors.red)
                    : Colors.white)
                .withOpacity(0.35),
            blurRadius: 22,
            spreadRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_feedbackVisible) ...[
            Icon(
              _lastCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
          ],
          Text(
            _current?.word ?? '',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Feedback banner (shown on wrong answer / miss) ────────────────────────
  Widget _buildFeedbackBanner() {
    final show = _feedbackVisible && !_lastCorrect && _current != null;
    if (!show) return const SizedBox.shrink();

    final correctZone = _zones.firstWhere((z) => z.id == _current!.cat);

    final String detail;
    if (widget.gameType == 'kjonn') {
      detail = '${correctZone.hint} ${_current!.word}';
    } else {
      detail = _current!.note; // e.g. "kastar / kasta"
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0040).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade300.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  children: [
                    TextSpan(
                      text: 'Riktig: ${correctZone.label}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: detail,
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category zones ─────────────────────────────────────────────────────────
  Widget _buildZones() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
      child: Row(
        children: _zones.map((zone) {
          final isPickedWrong =
              _feedbackVisible && _pickedZoneId == zone.id && !_lastCorrect;
          final isCorrectZone =
              _feedbackVisible && zone.id == _current?.cat;

          Color col = zone.color;
          if (isCorrectZone) col = Colors.green.shade600;
          if (isPickedWrong) col = Colors.red.shade600;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _handleAnswer(zone.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [col.withOpacity(0.9), col],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: col.withOpacity(0.45),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(zone.icon, color: Colors.white, size: 22),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          zone.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        zone.hint,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Game over ──────────────────────────────────────────────────────────────
  Widget _buildGameOver() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💔', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            const Text(
              'Spelet er slutt!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score poeng',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivå $_level  •  $_correctCount rette svar',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Prøv igjen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D0225),
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => context.go('/practice'),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
              label: const Text(
                'Tilbake til øvingar',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Decorative stars background ────────────────────────────────────────────
class _StarsPainter extends CustomPainter {
  static final List<(double, double, double)> _stars = List.generate(
    55,
    (i) {
      final rng = Random(i * 7919);
      return (rng.nextDouble(), rng.nextDouble(), rng.nextDouble() * 2 + 0.5);
    },
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.45);
    for (final (rx, ry, r) in _stars) {
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
