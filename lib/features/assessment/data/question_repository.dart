import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

class QuestionRepository {
  List<Question>? _cachedQuestions;

  Future<List<Question>> getAllQuestions() async {
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }
    
    final jsonString = await rootBundle.loadString('assets/data/questions.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final List<dynamic> questionList = jsonMap['questions'];
    
    _cachedQuestions = questionList.map((e) => Question.fromJson(e)).toList();
    return _cachedQuestions!;
  }

  Future<List<Question>> getQuestionsForAssessment() async {
    final all = await getAllQuestions();
    
    // Lag en kopi og bland for variasjon
    final shuffled = List<Question>.from(all)..shuffle();
    
    // Velg 3 fra hver kategori for en grundig kartlegging
    final Set<String> categories = all.map((q) => q.category).toSet();
    final List<Question> selected = [];
    
    for (var cat in categories) {
      final qs = shuffled.where((element) => element.category == cat).take(3);
      selected.addAll(qs);
    }
    
    selected.shuffle();
    return selected;
  }

  Future<List<Question>> getQuestionsForPractice(Map<String, double> categoryMastery) async {
    final all = await getAllQuestions();
    
    // Velg kategorier med lavest mestring
    final weakCategories = categoryMastery.entries.where((e) => e.value < 0.6).map((e) => e.key).toList();
    
    final shuffled = List<Question>.from(all)..shuffle();
    final List<Question> selected = [];
    
    // Plukk 10 fra svake sider
    int weakCount = 0;
    for (var q in shuffled) {
       if (weakCategories.contains(q.category) && weakCount < 10) {
          selected.add(q);
          weakCount++;
       }
    }
    
    // Fyll opp til 15 oppgaver med tilfeldige andre
    for (var q in shuffled) {
       if (!selected.contains(q) && selected.length < 15) {
          selected.add(q);
       }
    }
    
    selected.shuffle();
    return selected;
  }
}
