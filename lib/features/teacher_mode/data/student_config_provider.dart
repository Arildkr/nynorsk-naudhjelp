import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';

class StudentConfig {
  final String roomCode;
  final String name;
  StudentConfig(this.roomCode, this.name);
}

final studentConfigProvider =
    StateNotifierProvider<StudentConfigNotifier, StudentConfig?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StudentConfigNotifier(prefs);
});

class StudentConfigNotifier extends StateNotifier<StudentConfig?> {
  final SharedPreferences _prefs;
  static const _keyRoom = 'student_room_code';
  static const _keyName = 'student_name';

  StudentConfigNotifier(this._prefs) : super(null) {
    _load();
  }

  void _load() {
    final room = _prefs.getString(_keyRoom);
    final name = _prefs.getString(_keyName);
    if (room != null && name != null) {
      state = StudentConfig(room, name);
    }
  }

  void set(StudentConfig? config) {
    state = config;
    if (config != null) {
      _prefs.setString(_keyRoom, config.roomCode);
      _prefs.setString(_keyName, config.name);
    } else {
      _prefs.remove(_keyRoom);
      _prefs.remove(_keyName);
    }
  }
}

/// Persistent student-ID — genererast éin gong og lagra i SharedPreferences
final studentIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const key = 'student_device_id';
  var id = prefs.getString(key);
  if (id == null) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Object().hashCode.abs();
    id = '${now.toRadixString(16)}-${rand.toRadixString(16)}';
    prefs.setString(key, id);
  }
  return id;
});
