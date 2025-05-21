import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.freezed.dart';

@freezed
class Quiz with _$Quiz {
  const Quiz({
    required this.question,
    required this.options,
    required this.explanation,
    this.correctOptionIndex = 0,
    this.relatedSkill = '',
    this.answer = '',
  });

  final String question;
  final List<String> options;
  final String explanation;
  final int correctOptionIndex;
  final String relatedSkill;
  final String answer; // 이전 호환성을 위해 유지
}
