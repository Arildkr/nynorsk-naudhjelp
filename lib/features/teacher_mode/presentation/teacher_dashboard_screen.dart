import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../data/teacher_repository.dart';
import '../../../../main.dart';

final currentRoomProvider =
    StateNotifierProvider<_RoomNotifier, String?>(
  (ref) => _RoomNotifier(ref.watch(sharedPreferencesProvider)),
);

class _RoomNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  static const _key = 'teacher_room_code';

  _RoomNotifier(this._prefs) : super(_prefs.getString(_key));

  void set(String? code) {
    state = code;
    if (code != null) {
      _prefs.setString(_key, code);
    } else {
      _prefs.remove(_key);
    }
  }
}
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
        title: const Text('Lærarportal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: roomCode == null
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _buildStartScreen(context, ref),
              ),
            )
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
            const Text('Gjer deg klar for klassen!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'Når du opprettar eit rom, får du ein firesifra kode. Be elevane skrive inn denne koden før dei startar kartlegginga.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.5),
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
                ref.read(currentRoomProvider.notifier).set(code);
              },
              child: const Text('Opprett rom', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDashboard(BuildContext context, WidgetRef ref, String roomCode) {
    final studentsAsync = ref.watch(roomStreamProvider(roomCode));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text('Firebase-feil:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            SelectableText(err.toString(), style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
      data: (students) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: _buildRoomCodeCard(context, ref, roomCode),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Text('Elevar i arbeid', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text('${students.length}'),
                      backgroundColor: Colors.blueGrey.shade100,
                    ),
                  ],
                ),
              ),
                ),
              ),
            ),
            if (students.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Ventar på at elevar skal kople seg til...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStudentCard(context, ref, students[index], roomCode),
                    childCount: students.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRoomCodeCard(BuildContext context, WidgetRef ref, String roomCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: Colors.blueGrey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Romkode', style: TextStyle(fontSize: 13, color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text(
                      roomCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                    const Text('Skriv denne på tavla!', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Romkode kopiert!'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                    label: const Text('Kopier', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(currentRoomProvider.notifier).set(null),
                    icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                    label: const Text('Avslutt rom', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, StudentProgress s, String roomCode) {
    final maxQ = max(1, s.totalQuestions);
    final pct = s.score / maxQ;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showStudentDetail(context, s),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: s.isFinished ? Colors.green.shade200 : Colors.blueGrey.shade200,
                child: Text(
                  s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: s.isFinished ? Colors.green : Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.isFinished
                          ? 'Ferdig — ${s.score} av ${s.totalQuestions} rette (${(pct * 100).toInt()}%)'
                          : 'Jobbar... ${s.score} av ${s.totalQuestions} rette',
                      style: TextStyle(
                        color: s.isFinished ? Colors.green.shade700 : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: s.isFinished ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (s.weakCategory.isNotEmpty)
                Chip(
                  label: Text(_formatCategory(s.weakCategory), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.orange.shade100,
                  padding: EdgeInsets.zero,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
                tooltip: 'Detaljar',
                onPressed: () => _showStudentDetail(context, s),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                tooltip: 'Fjern elev',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Fjern elev?'),
                      content: Text('Vil du fjerne ${s.name} frå rommet?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Fjern', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(teacherRepositoryProvider).removeStudent(roomCode, s.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetail(BuildContext context, StudentProgress s) {
    final maxQ = max(1, s.totalQuestions);
    final pct = s.score / maxQ;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: s.isFinished ? Colors.green.shade200 : Colors.blueGrey.shade200,
                    child: Text(
                      s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(
                          s.isFinished ? 'Ferdig med kartlegging' : 'Kartlegging pågår...',
                          style: TextStyle(color: s.isFinished ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Overall score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (s.isFinished ? Colors.green : Colors.blueGrey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${s.score} av ${s.totalQuestions} rette — ${(pct * 100).toInt()}%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: s.isFinished ? Colors.green : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.categoryScores.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Per kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...s.categoryScores.entries.map((e) {
                  final cat = e.key;
                  final correct = e.value['correct'] ?? 0;
                  final total = e.value['total'] ?? 1;
                  final catPct = correct / total;
                  Color barColor = Colors.red.shade400;
                  if (catPct >= 0.8) barColor = Colors.green.shade500;
                  else if (catPct >= 0.5) barColor = Colors.orange;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatCategory(cat), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('$correct / $total', style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: catPct,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else if (s.isFinished) ...[
                const SizedBox(height: 16),
                const Text('Ingen kategoridata tilgjengeleg (gammal kartlegging)', style: TextStyle(color: Colors.grey)),
              ],
              if (s.weakCategory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Svakaste kategori: ${_formatCategory(s.weakCategory)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCategory(String key) {
  switch (key) {
    case 'substantiv_kjonn': return 'Substantiv — kjønn';
    case 'substantiv_boying': return 'Substantiv — bøying';
    case 'verb_boying': return 'Verb';
    case 'ordforrad': return 'Ordforråd';
    case 'pronomen': return 'Pronomen';
    case 'eiendomsord': return 'Eigedomsord';
    default: return key;
  }
}
