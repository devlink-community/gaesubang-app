import '../../domain/model/quiz.dart';
import '../dto/quiz_dto.dart';

extension QuizDtoMapper on QuizDto {
  Quiz toModel() {
    return Quiz(
      question: question ?? '정보를 불러올 수 없습니다',
      options: options?.map((e) => e.toString()).toList() ?? [],
      answer: answer ?? '',
      explanation: explanation ?? '',
      skillArea: skillArea ?? '컴퓨터 기초',
    );
  }
}

extension QuizModelMapper on Quiz {
  QuizDto toDto() {
    return QuizDto(
      question: question,
      options: options,
      answer: answer,
      explanation: explanation,
      skillArea: skillArea,
    );
  }
}
