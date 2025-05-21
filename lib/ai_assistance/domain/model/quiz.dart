import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.freezed.dart';

@freezed
class Quiz with _$Quiz {
  const Quiz({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.skillArea = '',
  });

  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final String skillArea;
}
