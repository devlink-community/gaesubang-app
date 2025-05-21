import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_tip.freezed.dart';

@freezed
class StudyTip with _$StudyTip {
  const StudyTip({
    required this.title,
    required this.content,
    required this.relatedSkill,
    required this.englishPhrase,
    required this.translation,
    this.source,
  });

  final String title;
  final String content;
  final String relatedSkill;
  final String englishPhrase;
  final String translation;
  final String? source;
}