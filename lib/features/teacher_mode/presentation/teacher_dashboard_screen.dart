import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../data/teacher_repository.dart';

final currentRoomProvider = StateProvider<String?>((ref) => null);
final roomStreamProvider = StreamProvider.autoDispose.family<List<StudentProgress>, String>((ref, roomCode) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.watchRoom(roomCode);
});

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomCode = ref.watch(currentRoomProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lærerportal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: roomCode == null
          ? _buildStartScreen(context, ref)
          : _buildLiveDashboard(context, ref, roomCode),
    );
  }

  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.co_present, size: 100, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              'Gjør deg klar for klassen!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              'Når du oppretter et rom, får du en firesifret kode. Be elevene skrive inn denne koden før de starter kartleggingen, så dukker de opp her i sanntid!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final code = (Random().nextInt(9000) + 1000).toString();
                await ref.read(teacherRepositoryProvider).createRoom(code);
                ref.read(currentRoomProvider.notifier).state = code;
              },
              child: const Text('Opprett Rom', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDashboard(BuildContext context, WidgetRef ref, String roomCode) {
    final studentsAsync = ref.watch(roomStreamProvider(roomCode));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.blueGrey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Text('Romkode:', style: TextStyle(fontSize: 24)),
                  Text(
                    roomCode,
                    style: const TextStyle(fontSize: 100, fontWeight: FontWeight.w900, letterSpacing: 16),
                  ),
                  const Text('Skriv denne på tavla!', style: TextStyle(color: Colors.blueGrey, fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Elever i arbeid:', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Feil ved lesing: $err')),
              data: (students) {
                if (students.isEmpty) {
                  return const Center(child: Text('Venter på at elever skal koble seg til...', style: TextStyle(fontSize: 20, color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final maxQ = max(1, s.totalQuestions);
                    final pct = s.score / maxQ;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blueGrey.shade200,
                              child: Text(s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(fontSize: 24, color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 12,
                                      backgroundColor: Colors.grey.shade300,
                                      color: s.isFinished ? Colors.green : Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.isFinished 
                                      ? 'Ferdig! Score: ${(pct * 100).toInt()}%' 
                                      : 'Jobber... (${s.score} riktige så langt)',
                                    style: TextStyle(color: s.isFinished ? Colors.green : Colors.grey.shade700, fontWeight: s.isFinished ? FontWeight.bold : FontWeight.normal),
                                  ),
                                ],
                              ),
                            ),
                            if (s.weakCategory.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Chip(
                                  label: Text('Sliter med: ${s.weakCategory}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.orange.shade100,
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
