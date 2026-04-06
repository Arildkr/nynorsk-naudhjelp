import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ── Data models ────────────────────────────────────────────────────────────

class _TextEntry {
  final String title;
  final String raw; // template: [bokmål|nynorsk] for errors, plain for correct
  const _TextEntry(this.title, this.raw);
}

class _Token {
  final String display;
  final bool isError;
  final String? correction;
  final String? trailing; // punctuation stripped from the token
  const _Token({
    required this.display,
    this.isError = false,
    this.correction,
    this.trailing,
  });
}

enum _ChipState { normal, correct }

// ── Parser ─────────────────────────────────────────────────────────────────

List<_Token> _parseText(String raw) {
  final tokens = <_Token>[];
  for (final part in raw.split(' ')) {
    if (part.startsWith('[') && part.contains('|')) {
      // Error token: [bokmål|nynorsk] possibly with trailing punct after ]
      String inner = part.replaceAll('[', '').replaceAll(']', '');
      String trailingPunct = '';
      if (inner.isNotEmpty && '.,;:!?'.contains(inner[inner.length - 1])) {
        trailingPunct = inner[inner.length - 1];
        inner = inner.substring(0, inner.length - 1);
      }
      final halves = inner.split('|');
      tokens.add(_Token(
        display: halves[0],
        isError: true,
        correction: halves.length > 1 ? halves[1] : null,
        trailing: trailingPunct.isEmpty ? null : trailingPunct,
      ));
    } else {
      // Plain word — strip trailing punctuation
      String word = part;
      String trailing = '';
      if (word.isNotEmpty && '.,;:!?'.contains(word[word.length - 1])) {
        trailing = word[word.length - 1];
        word = word.substring(0, word.length - 1);
      }
      tokens.add(_Token(
        display: word,
        trailing: trailing.isEmpty ? null : trailing,
      ));
    }
  }
  return tokens;
}

// ── Game screen ─────────────────────────────────────────────────────────────

class FindErrorGameScreen extends StatefulWidget {
  const FindErrorGameScreen({super.key});

  @override
  State<FindErrorGameScreen> createState() => _FindErrorGameScreenState();
}

class _FindErrorGameScreenState extends State<FindErrorGameScreen>
    with TickerProviderStateMixin {
  // ── Level data ─────────────────────────────────────────────────────────────

  static const _level1Texts = [
    _TextEntry('Frukost',
        '[Jeg|Eg] et frukost no. Det er [ikke|ikkje] så [mye|mykje] mat igjen. [Jeg|eg] må kjøpe meir brød [hvis|viss] eg skal bli mett.'),
    _TextEntry('Skulen',
        'Det skal [være|vere] prøve i dag. [Jeg|Eg] har [ikke|ikkje] øvd [mye|mykje] nok. Læraren seier at [jeg|eg] må konsentrere meg meir.'),
    _TextEntry('Været',
        'Sola skin, men det er [ikke|ikkje] varmt. [Jeg|Eg] skal [være|vere] ute uansett. [Jeg|eg] treng [bare|berre] ei jakke.'),
    _TextEntry('Hobby',
        '[Jeg|Eg] likar å teikne. Det er [ikke|ikkje] vanskeleg. [Jeg|eg] bruker [mye|mykje] tid på det [hvis|viss] eg har fri.'),
    _TextEntry('Katten',
        '[Jeg|Eg] har ein katt. Han vil [ikke|ikkje] inn. [Jeg|eg] må [være|vere] tolmodig [hvis|viss] han skal kome.'),
    _TextEntry('Bussen',
        '[Jeg|Eg] ser bussen no. Han er [ikke|ikkje] langt unna. [Jeg|eg] må springe [mer|meir] for å rekke han. [Da|Då] rekk eg det.'),
    _TextEntry('Vennen',
        '[Jeg|Eg] skal møte ein ven. Me skal [være|vere] på biblioteket. Han er [ikke|ikkje] der [enda|endå]. [Jeg|eg] gler meg.'),
    _TextEntry('Trening',
        '[Jeg|Eg] skal springe ein tur. Det er [ikke|ikkje] tungt. [Jeg|eg] vil [være|vere] i god form til sommaren. [Da|Då] er eg klar.'),
    _TextEntry('Kino',
        '[Jeg|Eg] skal på kino. Filmen er [ikke|ikkje] begynt [enda|endå]. [Jeg|eg] må [være|vere] der før klokka sju.'),
    _TextEntry('Hagen',
        '[Jeg|Eg] ser [noen|nokon] blomar. Dei er [ikke|ikkje] raude. [Jeg|eg] skal [være|vere] i hagen i heile dag.'),
  ];

  static const _level2Texts = [
    _TextEntry('Hytta',
        '[Jeg|Eg] skal på hytta. Der skal eg [være|vere] [sammen|saman] med familien. [Hvis|Viss] det er snø, skal me gå [mye|mykje] på ski. [Jeg|eg] har [ikke|ikkje] [noen|nokon] ski som passar [enda|endå]. De må hjelpe meg å finne [noen|nokon] meir.'),
    _TextEntry('Sommar',
        '[Jeg|Eg] gler meg til ferie. [Da|Då] skal [jeg|eg] [være|vere] ved sjøen. [Hvis|Viss] det blir varmt, skal eg bade [mye|mykje]. [Jeg|eg] har [ikke|ikkje] sett [noen|nokon] krabbar her. De må [være|vere] med ut.'),
    _TextEntry('Byen',
        'Det er [mye|mykje] folk i byen. [Jeg|Eg] likar [ikke|ikkje] å [være|vere] der når det er kaos. [Hvis|Viss] man skal handle, må man ha [mer|meir] tid. [Jeg|eg] ser [ikke|ikkje] [noen|nokon] ledige plassar [enda|endå].'),
    _TextEntry('Skogen',
        '[Jeg|Eg] går i skogen. Det er [ikke|ikkje] [noen|nokon] dyr å sjå. [Hvis|Viss] [jeg|eg] er stille, kan eg [være|vere] heldig. [Jeg|eg] har [ikke|ikkje] sett [noen|nokon] rev [enda|endå]. De må gå meir stille.'),
    _TextEntry('Middagen',
        '[Jeg|Eg] skal lage mat. Det blir [ikke|ikkje] [noen|nokon] stor middag. [Jeg|eg] treng [bare|berre] [noen|nokon] poteter. [Hvis|Viss] eg finn [mer|meir] krydder, blir det [mye|mykje] betre. Eg skal [være|vere] kokk.'),
    _TextEntry('Kvelden',
        '[Jeg|Eg] sit inne. Det er [ikke|ikkje] [noen|nokon] stjerner på himmelen. [Hvis|Viss] det blir klart, skal [jeg|eg] [være|vere] ute. [Jeg|eg] har [enda|endå] [ikke|ikkje] sett månen. De må [være|vere] med.'),
    _TextEntry('Reisa',
        '[Jeg|Eg] har pakka bagen. [Jeg|eg] skal [være|vere] borte lenge. [Hvis|Viss] [jeg|eg] gløymer noko, er det [ikke|ikkje] [noen|nokon] krise. [Jeg|eg] har [enda|endå] [mye|mykje] plass. De må ikkje seinke meg.'),
    _TextEntry('Vinter',
        '[Jeg|Eg] ser ut på snøen. Det er [ikke|ikkje] [noen|nokon] som går ute. [Hvis|Viss] det blir [mer|meir] kaldt, må me [være|vere] inne. [Jeg|eg] har [enda|endå] [ikke|ikkje] funne vottane. [Da|Då] vert eg lei.'),
    _TextEntry('Biblioteket',
        '[Jeg|Eg] skal låne [noen|nokon] bøker. [Jeg|eg] har [ikke|ikkje] lese [mer|meir] enn to. [Hvis|Viss] [jeg|eg] finn [noen|nokon] gode, skal eg [være|vere] her lenge. Eg har [enda|endå] mykje å lære.'),
    _TextEntry('Heime',
        '[Jeg|Eg] skal vaske huset. Det er [ikke|ikkje] [noen|nokon] veg utanom. [Hvis|Viss] [jeg|eg] gjer det no, kan eg [være|vere] fri i kveld. [Jeg|eg] har [enda|endå] [mye|mykje] igjen. De må [bare|berre] bidra.'),
  ];

  static const _level3Texts = [
    _TextEntry('Oppdrag 1',
        '[Jeg|Eg] vakna seint i dag. [Jeg|eg] trur [ikke|ikkje] [jeg|eg] rekker skulen [hvis|viss] eg [ikke|ikkje] spring [mer|meir]. Det skal [være|vere] eit møte der alle må [være|vere] med. [Jeg|eg] har [enda|endå] [ikke|ikkje] fått [noen|nokon] beskjed. De sa det var [bare|berre] ein tur. Det er [ikke|ikkje] noko veg utanom.'),
    _TextEntry('Oppdrag 2',
        '[Jeg|Eg] skal skrive nynorsk. Det er [ikke|ikkje] alltid lett [hvis|viss] man [ikke|ikkje] øver [mye|mykje]. [Jeg|eg] vil [være|vere] flink, men [jeg|eg] gjer endå [noen|nokon] feil. De må [være|vere] snille og hjelpe meg [mer|meir]. [Jeg|eg] ser [ikke|ikkje] [noen|nokon] grunn til å gje opp. Det er [bare|berre] snakk om tid.'),
    _TextEntry('Oppdrag 3',
        '[Jeg|Eg] sit på kafé. Det er [ikke|ikkje] [noen|nokon] ledige bord [enda|endå]. [Jeg|eg] ser [mye|mykje] folk som skal [være|vere] sosiale. [Hvis|Viss] [jeg|eg] finn ein plass, skal eg sitje der [mer|meir]. [Jeg|eg] har [ikke|ikkje] fått kaffien min [enda|endå]. De må [være|vere] klare til å gå [sammen|saman].'),
    _TextEntry('Oppdrag 4',
        '[Jeg|Eg] skal på fjellet. Det skal [være|vere] ein lang tur. [Hvis|Viss] det blir dårleg ver, må me [være|vere] forsiktige. [Jeg|eg] har [enda|endå] [ikke|ikkje] pakka [noen|nokon] ekstra klede. De må [ikke|ikkje] gløyme noko [mer|meir]. [Da|Då] blir det vanskeleg. Det er [ikke|ikkje] [noen|nokon] spøk å [være|vere] på vidda [sammen|saman].'),
    _TextEntry('Oppdrag 5',
        '[Jeg|Eg] ser på nyheitene. Det skjer [mye|mykje] i verda. [Hvis|Viss] man [ikke|ikkje] følgjer med, veit man [ikke|ikkje] [noen|nokon] ting. [Jeg|eg] skal [være|vere] flinkare til å lese [mer|meir]. [Bare|Berre] ved å øve kan man bli meir kritisk. [Jeg|eg] ser [ikke|ikkje] [noen|nokon] grunn til å gje opp [enda|endå]. Det er [ikke|ikkje] berre spøk.'),
    _TextEntry('Oppdrag 6',
        '[Jeg|Eg] skal pusse opp huset. Det blir [mye|mykje] arbeid. [Hvis|Viss] [jeg|eg] skal [være|vere] ferdig til jul, må eg jobbe [mer|meir]. [Jeg|eg] har [enda|endå] [ikke|ikkje] kjøpt [noen|nokon] maling. De må [være|vere] med og hjelpe. Det er [ikke|ikkje] [noen|nokon] veg utanom [hvis|viss] me skal bli ferdige [sammen|saman].'),
    _TextEntry('Oppdrag 7',
        '[Jeg|Eg] skal på konsert. Det skal [være|vere] [mye|mykje] folk der. [Hvis|Viss] [jeg|eg] [ikke|ikkje] finn billetten, blir eg sprø. [Jeg|eg] har [enda|endå] [ikke|ikkje] sett [noen|nokon] som har ein ekstra. De må [være|vere] klare. Det er [ikke|ikkje] [noen|nokon] vits i å vente [mer|meir]. [Da|Då] er det for seint.'),
    _TextEntry('Oppdrag 8',
        '[Jeg|Eg] skal lære meg å kode. Det er [ikke|ikkje] så vanskeleg [hvis|viss] man har [noen|nokon] å spørje. [Jeg|eg] vil [være|vere] ein ekspert. [Jeg|eg] har [enda|endå] [mye|mykje] å lære. De må [være|vere] tolmodige med meg. [Jeg|eg] ser [ikke|ikkje] [noen|nokon] hindringar [mer|meir]. [Bare|Berre] vent og sjå.'),
    _TextEntry('Oppdrag 9',
        '[Jeg|Eg] skal reise med tog. Det skal [være|vere] ein fin tur. [Hvis|Viss] toget er i rute, skal eg [være|vere] framme klokka åtte. [Jeg|eg] har [enda|endå] [ikke|ikkje] kjøpt [noen|nokon] mat. De må [ikke|ikkje] gløyme å ta med [mer|meir] vatn. Me skal sitje [sammen|saman] og [være|vere] glade. [Jeg|eg] gler meg [mye|mykje]. [Da|Då] blir det bra.'),
    _TextEntry('Oppdrag 10',
        '[Jeg|Eg] ser ut over havet. Det er [ikke|ikkje] [noen|nokon] båtar der [enda|endå]. [Hvis|Viss] det blir vind, skal me [være|vere] inne. [Jeg|eg] har [enda|endå] [mye|mykje] arbeid å gjere. De må [være|vere] flinke og hjelpe til [mer|meir]. Det er [ikke|ikkje] [noen|nokon] veg utanom [hvis|viss] me skal rekke det. [Da|Då] kjem me i mål.'),
  ];

  // ── Game phase ─────────────────────────────────────────────────────────────
  bool _levelSelectPhase = true;
  bool _gameOverPhase = false;
  bool _levelCompletePhase = false;

  // ── Game state ─────────────────────────────────────────────────────────────
  int _selectedLevel = 0;
  int _lives = 3;
  int _score = 0;
  List<_TextEntry> _shuffledTexts = [];
  int _textIndex = 0;
  List<_Token> _tokens = [];
  List<_ChipState> _chipStates = []; // one entry per error token
  List<int> _errorTokenIndices = []; // flat token indices of all error tokens
  int _errorsFoundThisText = 0;
  int _totalErrorsInText = 0;
  int _totalErrorsFound = 0;

  final Random _rng = Random(DateTime.now().microsecondsSinceEpoch);

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _flashCtrl;
  int? _flashingTokenIndex; // flat token index of the chip currently flashing

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _flashingTokenIndex = null);
          if (_lives <= 0) {
            setState(() => _gameOverPhase = true);
          }
        }
      });
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  // ── Level management ───────────────────────────────────────────────────────
  void _startLevel(int level) {
    final source = level == 1
        ? _level1Texts
        : level == 2
            ? _level2Texts
            : _level3Texts;
    final shuffled = List<_TextEntry>.from(source)..shuffle(_rng);
    setState(() {
      _selectedLevel = level;
      _lives = 3;
      _score = 0;
      _totalErrorsFound = 0;
      _shuffledTexts = shuffled;
      _levelSelectPhase = false;
      _gameOverPhase = false;
      _levelCompletePhase = false;
    });
    _loadText(0);
  }

  void _loadText(int index) {
    final tokens = _parseText(_shuffledTexts[index].raw);
    final errorIndices = <int>[];
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].isError) errorIndices.add(i);
    }
    setState(() {
      _tokens = tokens;
      _errorTokenIndices = errorIndices;
      _chipStates = List.filled(errorIndices.length, _ChipState.normal);
      _totalErrorsInText = errorIndices.length;
      _errorsFoundThisText = 0;
      _textIndex = index;
      _flashingTokenIndex = null;
    });
  }

  void _nextText() {
    if (_textIndex + 1 >= _shuffledTexts.length) {
      setState(() => _levelCompletePhase = true);
    } else {
      _loadText(_textIndex + 1);
    }
  }

  void _restart() {
    setState(() {
      _levelSelectPhase = true;
      _gameOverPhase = false;
      _levelCompletePhase = false;
    });
  }

  // ── Tap handling ───────────────────────────────────────────────────────────
  void _onChipTap(int tokenIndex) {
    if (_gameOverPhase || _levelCompletePhase) return;
    if (_errorsFoundThisText == _totalErrorsInText) return; // text complete
    final token = _tokens[tokenIndex];
    final errorIdx = _errorTokenIndices.indexOf(tokenIndex);

    if (token.isError && errorIdx >= 0 && _chipStates[errorIdx] == _ChipState.normal) {
      // Correct find
      final pts = _selectedLevel == 1 ? 10 : _selectedLevel == 2 ? 15 : 20;
      setState(() {
        final updated = List<_ChipState>.from(_chipStates);
        updated[errorIdx] = _ChipState.correct;
        _chipStates = updated;
        _errorsFoundThisText++;
        _totalErrorsFound++;
        _score += pts;
      });
      HapticFeedback.lightImpact();
    } else if (!token.isError) {
      // Wrong tap — lose a life
      setState(() {
        _lives--;
        _flashingTokenIndex = tokenIndex;
      });
      HapticFeedback.mediumImpact();
      _flashCtrl.forward(from: 0);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_levelSelectPhase) return _buildLevelSelect();
    if (_gameOverPhase) return _buildGameOver();
    if (_levelCompletePhase) return _buildLevelComplete();
    return _buildGame();
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

  // ── Level select ───────────────────────────────────────────────────────────
  Widget _buildLevelSelect() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _hudIcon(
                Icons.arrow_back_rounded, () => context.go('/practice')),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.find_in_page_rounded,
                      color: Colors.white, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Finn feil!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Trykk på bokmålsord i dei nynorske tekstane',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  _buildLevelCard(1, 'Lærling', '5 feil per tekst',
                      Icons.school_rounded, const Color(0xFF1565C0)),
                  const SizedBox(height: 14),
                  _buildLevelCard(2, 'Detektiv', '10 feil per tekst',
                      Icons.search_rounded, const Color(0xFF6A1B9A)),
                  const SizedBox(height: 14),
                  _buildLevelCard(3, 'Ekspert', '15 feil per tekst',
                      Icons.military_tech_rounded, const Color(0xFFBF360C)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(
      int level, String name, String desc, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _startLevel(level),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('$desc · 10 tekstar',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Game ───────────────────────────────────────────────────────────────────
  Widget _buildGame() {
    final allFound = _errorsFoundThisText == _totalErrorsInText;
    return Column(
      children: [
        _buildHud(),
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: _buildTextArea(),
          ),
        ),
        if (allFound) _buildNextButton(),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  Widget _buildHud() {
    final levelName = _selectedLevel == 1
        ? 'Lærling'
        : _selectedLevel == 2
            ? 'Detektiv'
            : 'Ekspert';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _hudIcon(Icons.close_rounded, () => context.go('/practice')),
          const SizedBox(width: 6),
          _hudChip(Icons.star_rounded, Colors.amber, '$_score'),
          const SizedBox(width: 6),
          _hudChip(Icons.search_rounded, Colors.lightBlueAccent, levelName),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _shuffledTexts.isNotEmpty
                  ? _shuffledTexts[_textIndex].title
                  : '',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final alive = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    key: ValueKey('$i$alive'),
                    alive
                        ? Icons.favorite_rounded
                        : Icons.heart_broken_rounded,
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
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

  // ── Progress bar ───────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_errorsFoundThisText av $_totalErrorsInText feil funne',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Tekst ${_textIndex + 1} av ${_shuffledTexts.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _totalErrorsInText > 0
                  ? _errorsFoundThisText / _totalErrorsInText
                  : 0,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Text area ──────────────────────────────────────────────────────────────
  Widget _buildTextArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: AnimatedBuilder(
        animation: _flashCtrl,
        builder: (context, _) {
          int errorIdx = 0;
          final widgets = <Widget>[];
          for (int i = 0; i < _tokens.length; i++) {
            final token = _tokens[i];
            final currentErrorIdx = token.isError ? errorIdx : -1;
            if (token.isError) errorIdx++;
            widgets.add(_buildChip(token, i, currentErrorIdx));
            if (token.trailing != null) {
              widgets.add(Text(
                token.trailing!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 17, height: 1.5),
              ));
            }
          }
          return Wrap(
            spacing: 4,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: widgets,
          );
        },
      ),
    );
  }

  Widget _buildChip(_Token token, int tokenIndex, int errorIdx) {
    final isFound = token.isError &&
        errorIdx >= 0 &&
        _chipStates[errorIdx] == _ChipState.correct;
    final isFlashing = _flashingTokenIndex == tokenIndex;

    Color bgColor;
    Color textColor;
    String displayText;

    if (isFound) {
      bgColor = Colors.green.shade600;
      textColor = Colors.white;
      displayText = '${token.display} → ${token.correction ?? ''}';
    } else if (isFlashing) {
      final t = _flashCtrl.value;
      bgColor =
          Color.lerp(Colors.red.shade500, Colors.white.withOpacity(0.10), t)!;
      textColor = Colors.white;
      displayText = token.display;
    } else {
      bgColor = Colors.white.withOpacity(0.10);
      textColor = Colors.white.withOpacity(0.9);
      displayText = token.display;
    }

    return GestureDetector(
      onTap: () => _onChipTap(tokenIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFound
                ? Colors.green.shade400
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFound) ...[
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight:
                    isFound ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Next button ─────────────────────────────────────────────────────────────
  Widget _buildNextButton() {
    final isLast = _textIndex + 1 >= _shuffledTexts.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ElevatedButton.icon(
        onPressed: _nextText,
        icon: Icon(isLast
            ? Icons.emoji_events_rounded
            : Icons.arrow_forward_rounded),
        label: Text(isLast ? 'Sjå resultatet' : 'Neste tekst →'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Level complete ─────────────────────────────────────────────────────────
  Widget _buildLevelComplete() {
    final levelName = _selectedLevel == 1
        ? 'Lærling'
        : _selectedLevel == 2
            ? 'Detektiv'
            : 'Ekspert';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            const Text(
              'Nivå fullført!',
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
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1),
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
                    '$_totalErrorsFound feil funne  ·  $levelName',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _startLevel(_selectedLevel),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Prøv igjen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D0225),
                minimumSize: const Size(220, 52),
                textStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            if (_selectedLevel < 3) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _startLevel(_selectedLevel + 1),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Neste nivå'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 52),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => context.go('/practice'),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white54),
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
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 1),
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
                    '$_totalErrorsFound feil funne',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _startLevel(_selectedLevel),
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
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white54),
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
