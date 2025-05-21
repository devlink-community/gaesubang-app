import '../../domain/model/quiz.dart';
import '../dto/quiz_dto.dart';

extension QuizDtoMapper on QuizDto {
  Quiz toModel() {
    // 스킬 영역이 빈 문자열이면 "Flutter"로 설정
    final skill = skillArea?.isNotEmpty == true ? skillArea! : 'Flutter';

    return Quiz(
      question: question ?? '정보를 불러올 수 없습니다',
      options: options?.map((e) => e.toString()).toList() ?? [],
      explanation: explanation ?? '',
      correctOptionIndex: correctOptionIndex ?? 0,
      relatedSkill: skill, // 강제로 원본 스킬 설정
      answer: answer ?? '', // 이전 호환성을 위해 유지
    );
  }
}

extension QuizModelMapper on Quiz {
  QuizDto toDto() {
    return QuizDto(
      question: question,
      options: options,
      explanation: explanation,
      correctOptionIndex: correctOptionIndex,
      skillArea: relatedSkill,
      answer: answer,
    );
  }
}
