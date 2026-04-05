import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';

class StudentConfig {
  final String roomCode;
  final String name;

  StudentConfig(this.roomCode, this.name);
}

final studentConfigProvider = StateProvider<StudentConfig?>((ref) => null);

/// Persistent student-ID — genererast éin gong og lagra i SharedPreferences
/// slik at autoDispose-providerar ikkje lagar duplikate Firestore-oppføringar.
final studentIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const key = 'student_device_id';
  var id = prefs.getString(key);
  if (id == null) {
    // Enkel UUID-generering utan ekstern pakke
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Object().hashCode.abs();
    id = '${now.toRadixString(16)}-${rand.toRadixString(16)}';
    prefs.setString(key, id);
  }
  return id;
});
