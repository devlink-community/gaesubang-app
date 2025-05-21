import 'package:json_annotation/json_annotation.dart';

part 'quiz_dto.g.dart';

@JsonSerializable()
class QuizDto {
  const QuizDto({
    this.question,
    this.options,
    this.answer,
    this.explanation,
    this.skillArea,
  });

  final String? question;
  final List<String>? options;
  final String? answer;
  final String? explanation;
  final String? skillArea;

  factory QuizDto.fromJson(Map<String, dynamic> json) =>
      _$QuizDtoFromJson(json);
  Map<String, dynamic> toJson() => _$QuizDtoToJson(this);
}
