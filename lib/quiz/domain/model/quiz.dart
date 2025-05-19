import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.freezed.dart';

@freezed
class Quiz with _$Quiz {
  const Quiz({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.category,
    required this.generatedDate,
    this.attemptedAnswerIndex,
    this.isAnswered = false,
  });

  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String category;
  final DateTime generatedDate;
  final int? attemptedAnswerIndex;
  final bool isAnswered;
}
