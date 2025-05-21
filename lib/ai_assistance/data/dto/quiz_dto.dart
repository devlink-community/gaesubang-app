import 'package:json_annotation/json_annotation.dart';

part 'quiz_dto.g.dart';

@JsonSerializable()
class QuizDto {
  const QuizDto({
    this.question,
    this.options,
    this.explanation,
    this.correctOptionIndex,
    this.skillArea,
    this.answer, // 이전 호환성을 위해 유지
  });

  final String? question;
  final List<String>? options;
  final String? explanation;
  final int? correctOptionIndex;
  final String? skillArea;
  final String? answer; // 이전 호환성을 위해 유지

  factory QuizDto.fromJson(Map<String, dynamic> json) =>
      _$QuizDtoFromJson(json);
  Map<String, dynamic> toJson() => _$QuizDtoToJson(this);
}
