import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _GameEntry {
  final String route;
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  const _GameEntry(this.route, this.label, this.subtitle, this.icon, this.gradientColors);
}

class CategoryPickerScreen extends StatelessWidget {
  const CategoryPickerScreen({super.key});

  static const _games = [
    _GameEntry(
      '/games/kjonn',
      'Kva kjønn har substantivet?',
      'Hankjønn, hokjønn eller inkjekjønn?',
      Icons.sports_esports_rounded,
      [Color(0xFF1565C0), Color(0xFF7B1FA2)],
    ),
    _GameEntry(
      '/games/verb',
      'A-verb, e-verb eller sterkt verb?',
      'Sorter verba i rett gruppe',
      Icons.sports_esports_rounded,
      [Color(0xFFBF360C), Color(0xFF1B5E20)],
    ),
    _GameEntry(
      '/games/finn-feil',
      'Finn feil i teksten!',
      'Tap bokmålsord som skal vere nynorsk',
      Icons.find_in_page_rounded,
      [Color(0xFF004D40), Color(0xFF1A237E)],
    ),
    _GameEntry(
      '/games/sveip',
      'Nynorsk eller bokmål?',
      'Sveip kortet rett — kjenn att nynorske ord',
      Icons.swipe_rounded,
      [Color(0xFF1B5E20), Color(0xFF006064)],
    ),
    _GameEntry(
      '/games/tunnel',
      'Ending-tunnelen',
      'Styr ordet til rett bøyingsending',
      Icons.subway_rounded,
      [Color(0xFF311B92), Color(0xFF1A237E)],
    ),
  ];

  static const _categories = [
    _Category('substantiv_kjonn', 'Substantiv — kjønn', 'Hankjønn, hokjønn og inkjekjønn', Icons.category_rounded, Colors.deepPurple),
    _Category('substantiv_boying', 'Substantiv — bøying', 'Bestemt form, fleirtal og bøying', Icons.format_list_bulleted_rounded, Colors.indigo),
    _Category('verb_boying', 'Verb', 'Presens, preteritum og uregelmessige verb', Icons.bolt_rounded, Colors.pink),
    _Category('ordforrad', 'Ordforråd', 'Nynorske ord vs. bokmål', Icons.translate_rounded, Colors.orange),
    _Category('pronomen', 'Pronomen', 'Eg, du, ho, han, me, dei ...', Icons.person_rounded, Colors.teal),
    _Category('eiendomsord', 'Eigedomsord', 'Min, mi, mitt, vår, dykkar ...', Icons.lock_rounded, Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vel øving', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Kva vil du øve på?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Vel ein kategori og øv med forklaringar etter kvart svar.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: _categories.map((cat) => _buildCard(context, cat)).toList(),
              ),
              const SizedBox(height: 28),
              // ── Game section ──────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.sports_esports_rounded,
                            size: 16, color: Colors.deepPurple),
                        SizedBox(width: 6),
                        Text(
                          'Spillbaserte øvingar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...(_games.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGameCard(context, g),
                  ))),
              const SizedBox(height: 8),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, _GameEntry game) {
    return Card(
      elevation: 6,
      shadowColor: game.gradientColors.last.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(game.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: game.gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      game.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white70, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _Category cat) {
    return Card(
      elevation: 4,
      shadowColor: cat.color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/practice/category/${cat.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [cat.color.withOpacity(0.85), cat.color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat.icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cat.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cat.subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Category(this.id, this.label, this.subtitle, this.icon, this.color);
}
