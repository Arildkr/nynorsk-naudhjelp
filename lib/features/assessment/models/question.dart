enum QuestionType {
  multipleChoice,
  swipeChoice,
  fillIn,
  trueOrFalse,
  matching,
}

class Question {
  final String id;
  final QuestionType type;
  final String category;
  final int difficulty;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  Question({
    required this.id,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    QuestionType parseType(String t) {
      switch (t) {
        case 'SWIPE_CHOICE':
          return QuestionType.swipeChoice;
        case 'FILL_IN':
          return QuestionType.fillIn;
        case 'TRUE_FALSE':
          return QuestionType.trueOrFalse;
        case 'MATCHING':
          return QuestionType.matching;
        case 'MULTIPLE_CHOICE':
        default:
          return QuestionType.multipleChoice;
      }
    }

    return Question(
      id: json['id'] as String,
      type: parseType(json['type'] as String),
      category: json['category'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      text: json['text'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
    );
  }
}
