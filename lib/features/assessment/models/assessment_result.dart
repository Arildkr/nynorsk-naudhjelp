import 'dart:convert';

class AssessmentResult {
  final DateTime date;
  final int score;
  final int total;
  final Map<String, bool> categoryResults;

  AssessmentResult({
    required this.date,
    required this.score,
    required this.total,
    required this.categoryResults,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'score': score,
    'total': total,
    'categoryResults': categoryResults,
  };

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      date: DateTime.parse(json['date']),
      score: json['score'],
      total: json['total'],
      categoryResults: Map<String, bool>.from(json['categoryResults']),
    );
  }
}
