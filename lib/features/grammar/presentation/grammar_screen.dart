import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minigrammatikk', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _GrammarCard(
            title: 'Substantiv (Kjønn)',
            icon: Icons.category,
            color: Colors.blue,
            content: '''
På nynorsk har substantiv tre kjønn:
- Hankjønn: Ein gut - guten - gutar - gutane
- Hokjønn: Ei jente - jenta - jenter - jentene
- Inkjekjønn: Eit hus - huset - hus - husa

Hugs: Hokjønn endar OFTE på -e i ubestemt form (ei klokke, ei stjerne), og får a-ending i bestemt form eintal (klokka, stjerna).
Einstava inkjekjønnsord får INGEN ending i fleirtal (eit eple - fleire eple). Alle inkjekjønnsord endar på -a i bestemt fleirtal (epla, husa).
            ''',
          ),
          SizedBox(height: 16),
           _GrammarCard(
            title: 'Verb (A-verb og E-verb)',
            icon: Icons.directions_run,
            color: Colors.purple,
            content: '''
For svake verb er den største utfordringa skilje mellom a-verb og e-verb i fortid (preteritum):
- **A-verb**: Endar alltid på -a i preteritum.
  Eks: å kasta - kastar - kasta - har kasta
  Andre a-verb: sykla, elska, bada.

- **E-verb**: Får typisk endinga -te eller -de i preteritum.
  Eks: å kjøpe - kjøper - kjøpte - har kjøpt
  Andre e-verb: lyse, køyre, dømme.
            ''',
          ),
           SizedBox(height: 16),
           _GrammarCard(
            title: 'Spørreord (Ordbanken)',
            icon: Icons.question_mark,
            color: Colors.teal,
            content: '''
Nynorske spørjeord startar ofte med K og vert bytte ut konsekvent:
- Hvem → Kven
- Hva → Kva
- Hvor → Kvar
- Hvorfor → Kvifor
- Hvordan → Korleis
- Hvilken → Kva for (ein/ei/eit)
            ''',
          ),
           SizedBox(height: 16),
           _GrammarCard(
            title: 'Pronomen og Eiendomsord',
            icon: Icons.person,
            color: Colors.orange,
            content: '''
Pronomena du MÅ kunne i både subjektsform og objektsform:
- Eg → meg
- Du → deg
- Han → han
- Ho → henne
- Me/Vi → oss
- De → dykk
- Dei → dei

**Plassering av eigedomsord**:
På nynorsk skal eigedomsordet alltid stå ETTER substantivet:
Rett: Boka mi.
Feil (ofte): Min bok.
            ''',
          ),
        ],
      ),
    );
  }
}

class _GrammarCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _GrammarCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          childrenPadding: const EdgeInsets.all(24).copyWith(top: 0),
          children: [
            Text(
              content.trim(),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
