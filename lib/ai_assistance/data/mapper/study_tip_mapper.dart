// lib/ai_assistance/data/mapper/study_tip_mapper.dart

import '../../domain/model/study_tip.dart';
import '../dto/study_tip_dto.dart';

extension StudyTipDtoMapper on StudyTipDto {
  StudyTip toModel() {
    return StudyTip(
      title: title ?? '제목을 불러올 수 없습니다',
      content: content ?? '내용을 불러올 수 없습니다',
      relatedSkill: relatedSkill ?? '일반',
      englishPhrase: englishPhrase ?? 'English phrase not available',
      translation: translation ?? '번역을 불러올 수 없습니다',
      source: source,
    );
  }
}

extension StudyTipModelMapper on StudyTip {
  StudyTipDto toDto() {
    return StudyTipDto(
      title: title,
      content: content,
      relatedSkill: relatedSkill,
      englishPhrase: englishPhrase,
      translation: translation,
      source: source,
    );
  }
}