import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _TunnelRound {
  final String label;
  final String correctOption;
  final String resultForm;
  final List<String> allOptions; // exactly 4, will be shuffled each attempt
  const _TunnelRound(
      this.label, this.correctOption, this.resultForm, this.allOptions);
}

class _TunnelWord {
  final String stem;
  final String fullBase; // "ein gut", "å kaste"
  final Color genderColor;
  final List<_TunnelRound> rounds;
  const _TunnelWord(
      this.stem, this.fullBase, this.genderColor, this.rounds);
}

// ── Game mode ─────────────────────────────────────────────────────────────────

enum _TunnelMode { modeSelect, playing, gameDone }

// ── Word data ─────────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF4488FF);
const _kPink = Color(0xFFFF77AA);
const _kOrange = Color(0xFFFFAA33);
const _kGreen = Color(0xFF44DD88);
const _kCyan = Color(0xFF33DDEE);

const _substantivWords = [
  _TunnelWord('gut', 'ein gut', _kBlue, [
    _TunnelRound('Bestemt eintal', '-en', 'guten', ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-ar', 'gutar',
        ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-ane', 'gutane',
        ['-ene', '-ane', '-a', '-']),
  ]),
  _TunnelWord('jente', 'ei jente', _kPink, [
    _TunnelRound('Bestemt eintal', '-a', 'jenta', ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-er', 'jenter',
        ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-ene', 'jentene',
        ['-ene', '-ane', '-a', '-']),
  ]),
  _TunnelWord('hus', 'eit hus', _kOrange, [
    _TunnelRound('Bestemt eintal', '-et', 'huset', ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-', 'hus', ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-a', 'husa',
        ['-ene', '-ane', '-a', '-']),
  ]),
  _TunnelWord('sol', 'ei sol', _kPink, [
    _TunnelRound('Bestemt eintal', '-a', 'sola', ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-er', 'soler',
        ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-ene', 'solene',
        ['-ene', '-ane', '-a', '-']),
  ]),
  _TunnelWord('bil', 'ein bil', _kBlue, [
    _TunnelRound('Bestemt eintal', '-en', 'bilen', ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-ar', 'bilar',
        ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-ane', 'bilane',
        ['-ene', '-ane', '-a', '-']),
  ]),
  _TunnelWord('fjell', 'eit fjell', _kOrange, [
    _TunnelRound('Bestemt eintal', '-et', 'fjellet',
        ['-en', '-a', '-et', '-']),
    _TunnelRound('Ubest. fleirtal', '-', 'fjell',
        ['-er', '-ar', '-', '-a']),
    _TunnelRound('Best. fleirtal', '-a', 'fjella',
        ['-ene', '-ane', '-a', '-']),
  ]),
];

const _verbWords = [
  _TunnelWord('kast-', 'å kaste (a-verb)', _kGreen, [
    _TunnelRound('Presens', '-ar', 'kastar', ['-ar', '-er', '-', '-a']),
    _TunnelRound('Preteritum', '-a', 'kasta',
        ['-a', '-et', '-te', '(vokal)']),
    _TunnelRound('Perfektum', '-a', 'kasta',
        ['-a', '-t', '-', '(vokal)']),
  ]),
  _TunnelWord('snakk-', 'å snakke (a-verb)', _kGreen, [
    _TunnelRound('Presens', '-ar', 'snakkar', ['-ar', '-er', '-', '-a']),
    _TunnelRound('Preteritum', '-a', 'snakka',
        ['-a', '-et', '-te', '(vokal)']),
    _TunnelRound('Perfektum', '-a', 'snakka',
        ['-a', '-t', '-', '(vokal)']),
  ]),
  _TunnelWord('kjøp-', 'å kjøpe (e-verb)', _kCyan, [
    _TunnelRound('Presens', '-er', 'kjøper', ['-ar', '-er', '-', '-a']),
    _TunnelRound('Preteritum', '-te', 'kjøpte',
        ['-a', '-et', '-te', '(vokal)']),
    _TunnelRound('Perfektum', '-t', 'kjøpt',
        ['-a', '-t', '-', '(vokal)']),
  ]),
  _TunnelWord('høyr-', 'å høyre (e-verb)', _kCyan, [
    _TunnelRound('Presens', '-er', 'høyrer', ['-ar', '-er', '-', '-a']),
    _TunnelRound('Preteritum', '-de', 'høyrde',
        ['-a', '-et', '-de', '(vokal)']),
    _TunnelRound('Perfektum', '-d', 'høyrd',
        ['-a', '-d', '-', '(vokal)']),
  ]),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class TunnelGameScreen extends StatefulWidget {
  const TunnelGameScreen({super.key});

  @override
  State<TunnelGameScreen> createState() => _TunnelGameScreenState();
}

class _TunnelGameScreenState extends State<TunnelGameScreen>
    with TickerProviderStateMixin {
  // ── Game state ──────────────────────────────────────────────────────────────
  _TunnelMode _mode = _TunnelMode.modeSelect;
  late List<_TunnelWord> _words;
  int _wordIdx = 0;
  int _roundIdx = 0;
  int _lives = 3;
  int _score = 0;
  Color? _hintColor;

  // Lane: 0–3, vehicle starts at lane 1
  int _vehicleLane = 1;

  // Shuffled options for current round (index = lane)
  late List<String> _laneOptions;

  // Fall progress: 0.0 (top) → 1.0 (at vehicle)
  double _fallingY = 0.0;
  int _lastTickMs = 0;
  static const _fallMs = 4500; // ms to reach vehicle

  // Phase within playing
  bool _roundPaused = false; // true briefly after hit (success or fail)
  bool _wordComplete = false;
  List<String> _lastWordForms = [];
  String _lastSuccessForm = ''; // form shown in green flash

  // Collected forms: [wordIdx][roundIdx]
  late List<List<String?>> _collected;

  // Animations
  late Ticker _ticker;
  late AnimationController _tiltCtrl;
  late Animation<double> _tiltAnim;
  double _tiltStart = 0;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_tick);

    _tiltCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _tiltAnim = const AlwaysStoppedAnimation(0.0);
    _tiltCtrl.addListener(() => setState(() {}));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: _ShakeCurve()))
        .animate(_shakeCtrl);
    _shakeCtrl.addListener(() => setState(() {}));

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _successCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tiltCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Game control ────────────────────────────────────────────────────────────

  void _startGame(List<_TunnelWord> words) {
    setState(() {
      _words = List.from(words);
      _wordIdx = 0;
      _roundIdx = 0;
      _lives = 3;
      _score = 0;
      _hintColor = null;
      _vehicleLane = 1;
      _fallingY = 0;
      _lastTickMs = 0;
      _roundPaused = false;
      _wordComplete = false;
      _collected = [for (final _ in words) List.filled(3, null)];
      _mode = _TunnelMode.playing;
    });
    _shuffleRound();
    _ticker.start();
  }

  void _shuffleRound() {
    final opts = List<String>.from(
        _words[_wordIdx].rounds[_roundIdx].allOptions)
      ..shuffle(Random());
    _laneOptions = opts;
  }

  void _tick(Duration elapsed) {
    if (_mode != _TunnelMode.playing || _roundPaused || _wordComplete) return;
    final ms = elapsed.inMilliseconds;
    if (_lastTickMs == 0) {
      _lastTickMs = ms;
      return;
    }
    final dt = ms - _lastTickMs;
    _lastTickMs = ms;
    setState(() {
      _fallingY = (_fallingY + dt / _fallMs).clamp(0.0, 1.0);
      if (_fallingY >= 1.0) _processHit();
    });
  }

  void _processHit() {
    final hit = _laneOptions[_vehicleLane];
    final round = _words[_wordIdx].rounds[_roundIdx];
    _roundPaused = true;

    if (hit == round.correctOption) {
      // ── Correct ──
      HapticFeedback.mediumImpact();
      _score += 10;
      _collected[_wordIdx][_roundIdx] = round.resultForm;
      _lastSuccessForm = round.resultForm;
      _successCtrl.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        _hintColor = null;
        _roundIdx++;

        if (_roundIdx >= _words[_wordIdx].rounds.length) {
          // Word done
          _lastWordForms =
              _collected[_wordIdx].whereType<String>().toList();
          _wordIdx++;
          _roundIdx = 0;
          _wordComplete = true;

          Future.delayed(const Duration(milliseconds: 1400), () {
            if (!mounted) return;
            if (_wordIdx >= _words.length) {
              setState(() {
                _mode = _TunnelMode.gameDone;
                _ticker.stop();
              });
            } else {
              setState(() {
                _wordComplete = false;
                _roundPaused = false;
                _fallingY = 0;
                _lastTickMs = 0;
                _vehicleLane = 1;
              });
              _shuffleRound();
            }
          });
        } else {
          setState(() {
            _roundPaused = false;
            _fallingY = 0;
            _lastTickMs = 0;
            _vehicleLane = 1;
          });
          _shuffleRound();
        }
      });
    } else {
      // ── Wrong ──
      HapticFeedback.heavyImpact();
      _lives--;
      _hintColor = _words[_wordIdx].genderColor;

      if (_lives <= 0) {
        setState(() {
          _mode = _TunnelMode.gameDone;
          _ticker.stop();
        });
        return;
      }

      _shakeCtrl.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _roundPaused = false;
          _fallingY = 0;
          _lastTickMs = 0;
          _vehicleLane = 1;
        });
        _shuffleRound();
      });
    }
  }

  void _moveLane(int dir) {
    final newLane = (_vehicleLane + dir).clamp(0, 3);
    if (newLane == _vehicleLane) return;
    HapticFeedback.selectionClick();

    _tiltStart = _tiltAnim.value;
    _tiltAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: _tiltStart, end: -dir * 0.038),
          weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: -dir * 0.038, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 75),
    ]).animate(CurvedAnimation(parent: _tiltCtrl, curve: Curves.linear));

    _tiltCtrl.forward(from: 0);
    setState(() => _vehicleLane = newLane);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ending-tunnelen',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_mode == _TunnelMode.playing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: [
                ...List.generate(
                    3,
                    (i) => Icon(
                          i < _lives
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                          size: 18,
                        )),
                const SizedBox(width: 12),
                Text('$_score',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
              ]),
            ),
        ],
      ),
      body: switch (_mode) {
        _TunnelMode.modeSelect => _buildModeSelect(),
        _TunnelMode.playing => _buildPlaying(),
        _TunnelMode.gameDone => _buildDone(),
      },
    );
  }

  // ── Mode select ─────────────────────────────────────────────────────────────

  Widget _buildModeSelect() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚇',
                style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            const Text('Ending-tunnelen',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text(
              'Styr ordet til rett ending!\nTrykk til venstre eller høgre for å byte bane.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _modeBtn(
              'Substantiv',
              '6 ord — hankjønn, hokjønn og inkjekjønn',
              _kBlue,
              Icons.abc,
              () => _startGame(_substantivWords),
            ),
            const SizedBox(height: 14),
            _modeBtn(
              'Verb',
              '4 verb — a-verb og e-verb',
              _kGreen,
              Icons.edit_rounded,
              () => _startGame(_verbWords),
            ),
            const SizedBox(height: 14),
            _modeBtn(
              'Begge',
              'Substantiv + verb — alle 10 ord',
              Colors.purple,
              Icons.shuffle_rounded,
              () => _startGame([
                ..._substantivWords,
                ..._verbWords,
              ]..shuffle(Random())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(String title, String sub, Color color, IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.08)
          ]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(sub,
                      style: TextStyle(
                          color: color.withOpacity(0.65),
                          fontSize: 13)),
                ]),
          ),
        ]),
      ),
    );
  }

  // ── Playing ─────────────────────────────────────────────────────────────────

  Widget _buildPlaying() {
    final shakeX = _shakeCtrl.isAnimating ? _shakeAnim.value * 10 : 0.0;
    final tilt =
        _tiltCtrl.isAnimating ? _tiltAnim.value : 0.0;

    return Column(
      children: [
        // Tunnel (65%)
        Expanded(
          flex: 65,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              if (_roundPaused || _wordComplete) return;
              final half =
                  MediaQuery.of(context).size.width / 2;
              _moveLane(d.localPosition.dx < half ? -1 : 1);
            },
            child: Transform.translate(
              offset: Offset(shakeX, 0),
              child: Transform.rotate(
                angle: tilt,
                child: _buildTunnel(),
              ),
            ),
          ),
        ),
        // Dashboard (35%)
        Expanded(
          flex: 35,
          child: _buildDashboard(),
        ),
      ],
    );
  }

  Widget _buildTunnel() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final laneW = w / 4;

      // Vehicle x (animated between lanes)
      final vehicleLeft =
          laneW * _vehicleLane + (laneW - 116) / 2;

      return Stack(
        children: [
          // Tunnel painter (background + lane lines)
          CustomPaint(
            painter: _TunnelPainter(hintColor: _hintColor),
            size: Size(w, h),
          ),

          // Falling ending boxes — follow perspective lines from vp
          if (!_roundPaused && !_wordComplete)
            ...List.generate(4, (lane) {
              // Each lane's bottom-centre x
              final bottomX = laneW * lane + laneW / 2;
              // Vanishing point is top-centre
              final vp = w / 2;
              // Interpolate along perspective line: vp at t=0, bottomX at t=1
              final curX = vp + (bottomX - vp) * _fallingY;
              // y travels from near top to just above vehicle
              final curY = (h - 100) * _fallingY;
              // Scale: tiny at top, full-size at bottom
              final scale = 0.15 + 0.85 * _fallingY;
              final boxW = laneW * 0.84;
              final opt = _laneOptions[lane];
              final isCorrect = opt ==
                  _words[_wordIdx].rounds[_roundIdx].correctOption;
              final showHint = _hintColor != null && isCorrect;

              return Positioned(
                // Centre box on curX, accounting for scaled width
                left: curX - (boxW * scale) / 2,
                top: curY,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: boxW,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: showHint
                          ? _hintColor!.withOpacity(0.28)
                          : Colors.white.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: showHint
                            ? _hintColor!
                            : Colors.white.withOpacity(0.25),
                        width: showHint ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: showHint ? _hintColor : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),

          // Success flash
          if (_roundPaused && !_wordComplete)
            AnimatedBuilder(
              animation: _successCtrl,
              builder: (ctx, _) => Opacity(
                opacity:
                    (1 - _successCtrl.value).clamp(0.0, 1.0),
                child: Container(
                  color: Colors.greenAccent.withOpacity(0.15),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800
                            .withOpacity(0.9),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Text(
                        _lastSuccessForm.isEmpty ? '✓' : _lastSuccessForm,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Word complete overlay
          if (_wordComplete)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐',
                        style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 10),
                    const Text('Ord fullført!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _lastWordForms
                          .map((f) => Chip(
                                label: Text(f,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold)),
                                backgroundColor:
                                    Colors.green.shade700,
                                labelStyle: const TextStyle(
                                    color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

          // Vehicle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            left: vehicleLeft,
            bottom: 14,
            width: 116,
            height: 52,
            child: _VehicleWidget(
              stem: _words[_wordIdx < _words.length
                      ? _wordIdx
                      : _words.length - 1]
                  .stem,
              glowColor: _hintColor ?? Colors.cyanAccent,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDashboard() {
    final safeWordIdx =
        _wordIdx.clamp(0, _words.length - 1);
    final currentWord = _words[safeWordIdx];
    final safeRoundIdx =
        _roundIdx.clamp(0, currentWord.rounds.length - 1);

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current step label
          Text(
            _wordComplete
                ? 'Neste ord...'
                : '${currentWord.fullBase}  ·  ${currentWord.rounds[safeRoundIdx].label}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 6),

          // Scrollable word rows — one row per word, forms horizontal
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _wordIdx + 1, // only show words reached so far
              itemBuilder: (ctx, wi) {
                final word = _words[wi];
                final isCurrent = wi == safeWordIdx && !_wordComplete;
                final forms = wi < _collected.length
                    ? _collected[wi]
                    : <String?>[];

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF222222)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isCurrent
                            ? Colors.white24
                            : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      // Word base label
                      SizedBox(
                        width: 90,
                        child: Text(
                          word.fullBase,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Forms horizontally
                      ...List.generate(word.rounds.length, (ri) {
                        final form =
                            ri < forms.length ? forms[ri] : null;
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: form != null
                                ? Colors.green.shade800.withOpacity(0.5)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            form ?? word.rounds[ri].label.split(' ').first,
                            style: TextStyle(
                              color: form != null
                                  ? Colors.white
                                  : Colors.white24,
                              fontSize: 12,
                              fontWeight: form != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Done ────────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    final totalRounds =
        _words.fold<int>(0, (s, w) => s + w.rounds.length);
    final collected =
        _collected.expand((l) => l).whereType<String>().length;
    final pct = totalRounds > 0 ? collected / totalRounds : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pct >= 0.8 ? '🎉' : pct >= 0.5 ? '👍' : '📚',
                style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text('$_score poeng',
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('$collected av $totalRounds endingar rette',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  3,
                  (i) => Icon(
                        i < _lives
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 22,
                      )),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14)),
              ),
              onPressed: () {
                _ticker.stop();
                setState(() => _mode = _TunnelMode.modeSelect);
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

// ── Vehicle widget ────────────────────────────────────────────────────────────

class _VehicleWidget extends StatelessWidget {
  final String stem;
  final Color glowColor;
  const _VehicleWidget({required this.stem, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withOpacity(0.32), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.45),
                blurRadius: 22,
                spreadRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            stem,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tunnel painter ────────────────────────────────────────────────────────────

class _TunnelPainter extends CustomPainter {
  final Color? hintColor;
  const _TunnelPainter({this.hintColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient (dark → black)
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        hintColor?.withOpacity(0.18) ?? Colors.grey.shade900,
        Colors.black,
      ],
    );
    canvas.drawRect(
        bgRect, Paint()..shader = bgGrad.createShader(bgRect));

    // Perspective lane lines converging at vanishing point (top-center)
    final vp = Offset(size.width / 2, 0);
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final bx = size.width * i / 4;
      canvas.drawLine(Offset(bx, size.height), vp, linePaint);
    }

    // Speed-stripe horizontal lines (converging at vp)
    final hPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.8;
    for (int row = 1; row <= 10; row++) {
      final t = row / 10;
      final y = size.height * t;
      // Line width proportional to distance from vp
      final halfW = size.width / 2 * t;
      canvas.drawLine(
        Offset(size.width / 2 - halfW, y),
        Offset(size.width / 2 + halfW, y),
        hPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TunnelPainter old) =>
      old.hintColor != hintColor;
}

// ── Shake curve ───────────────────────────────────────────────────────────────

class _ShakeCurve extends Curve {
  @override
  double transformInternal(double t) => sin(t * pi * 4) * (1 - t);
}
