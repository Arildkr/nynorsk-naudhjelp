import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';

final xpProvider = StateNotifierProvider<XpNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return XpNotifier(prefs);
});

class XpNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  static const _key = 'total_xp';

  XpNotifier(this._prefs) : super(_prefs.getInt(_key) ?? 0);

  void add(int amount) {
    state += amount;
    _prefs.setInt(_key, state);
  }
}
