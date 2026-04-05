import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teacher_mode/data/student_config_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showJoinRoomDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kople til klasserom', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Viss læraren din har starta ein økt, kan du taste inn koden her.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Namnet ditt (t.d. Ola)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: 'Firesifra romkode'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Avbryt')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && roomController.text.isNotEmpty) {
                 ref.read(studentConfigProvider.notifier).state = StudentConfig(
                    roomController.text.trim(),
                    nameController.text.trim(),
                 );
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Kopla til rom! Du kan no starte kartlegginga.'), backgroundColor: Colors.green)
                 );
              }
            },
            child: const Text('Kople til'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(studentConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nynorsk naudhjelp', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Velkomen!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (currentConfig != null) 
                 Text(
                   'Kopla til rom: ${currentConfig.roomCode} som ${currentConfig.name}',
                   style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                   textAlign: TextAlign.center,
                 )
              else
                 const Text(
                   'Klar for å bli ein meister i nynorsk?',
                   style: TextStyle(fontSize: 16, color: Colors.grey),
                   textAlign: TextAlign.center,
                 ),
              const SizedBox(height: 32),
              _buildBigButton(
                context, 
                title: 'Start kartlegging', 
                subtitle: 'Sjekk nivået ditt og finn svake punkt', 
                icon: Icons.rocket_launch_rounded, 
                color: Colors.deepPurple,
                onTap: () => context.push('/assessment'),
              ),
              const SizedBox(height: 16),
              _buildBigButton(
                context, 
                title: 'Skreddarsydd øving', 
                subtitle: 'Tren eksplisitt på det du treng', 
                icon: Icons.fitness_center, 
                color: Colors.pink,
                onTap: () => context.push('/practice/flow'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      context, 
                      title: 'Resultat', 
                      subtitle: 'Di utvikling', 
                      icon: Icons.star_rounded, 
                      color: Colors.orange,
                      onTap: () => context.push('/results'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBigButton(
                      context, 
                      title: 'Grammatikk', 
                      subtitle: 'Oppslagsverk', 
                      icon: Icons.menu_book_rounded, 
                      color: Colors.teal,
                      onTap: () => context.push('/grammar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              if (currentConfig == null)
                ListTile(
                  leading: const Icon(Icons.login, color: Colors.blueAccent),
                  title: const Text('Bli med i klasserom (Romkode)'),
                  subtitle: const Text('Kople til læraren din si økt'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueAccent.withOpacity(0.5))),
                  onTap: () => _showJoinRoomDialog(context, ref),
                ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.co_present, color: Colors.blueGrey),
                  title: const Text('Lærarportal'),
                  subtitle: const Text('Start ein klasseromsøkt'),
                  tileColor: Colors.blueGrey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => context.push('/teacher'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13, 
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
