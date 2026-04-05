import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../models/assessment_result.dart';

final assessmentResultRepoProvider = Provider<AssessmentResultRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AssessmentResultRepository(prefs);
});

class AssessmentResultRepository {
  final SharedPreferences _prefs;
  static const _keyParams = 'assessment_history';

  AssessmentResultRepository(this._prefs);

  Future<void> saveResult(AssessmentResult result) async {
    final history = getHistory();
    history.add(result);
    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyParams, jsonList);
  }

  List<AssessmentResult> getHistory() {
    final list = _prefs.getStringList(_keyParams);
    if (list == null) return [];
    return list.map((e) => AssessmentResult.fromJson(jsonDecode(e))).toList();
  }
}
