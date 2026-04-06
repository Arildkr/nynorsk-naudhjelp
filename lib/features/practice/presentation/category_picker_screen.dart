import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryPickerScreen extends StatelessWidget {
  const CategoryPickerScreen({super.key});

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
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.blueGrey),
                ),
                title: const Text('Skreddarsydd øving', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Basert på kva du slit med frå kartlegginga'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blueGrey.shade200),
                ),
                onTap: () => context.push('/practice/flow'),
              ),
              const SizedBox(height: 16),
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
