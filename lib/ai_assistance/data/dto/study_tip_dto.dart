// lib/ai_assistance/data/dto/study_tip_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'study_tip_dto.g.dart';

@JsonSerializable()
class StudyTipDto {
  const StudyTipDto({
    this.title,
    this.content,
    this.relatedSkill,
    this.englishPhrase,
    this.translation,
    this.source,
  });

  final String? title;
  final String? content;
  final String? relatedSkill;
  final String? englishPhrase;
  final String? translation;
  final String? source;

  factory StudyTipDto.fromJson(Map<String, dynamic> json) =>
      _$StudyTipDtoFromJson(json);
  Map<String, dynamic> toJson() => _$StudyTipDtoToJson(this);
}