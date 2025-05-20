import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_source/quiz_dart_source.dart';
import '../data/repository_impl/quiz_repository_impl.dart';
import '../domain/repository/quiz_repository.dart';
import '../domain/use_case/answer_quiz_use_case.dart';
import '../domain/use_case/get_daily_quiz_usecase.dart';

part 'quiz_di.g.dart';

// DataSource Provider - VertexAI 사용
@riverpod
QuizDataSource quizDataSource(QuizDataSourceRef ref) {
  // VertexAI 구현체 반환
  return VertexAIQuizDataSourceImpl();
}

// Repository Provider
@riverpod
QuizRepository quizRepository(QuizRepositoryRef ref) {
  return QuizRepositoryImpl(dataSource: ref.watch(quizDataSourceProvider));
}

// UseCase Providers
@riverpod
GetDailyQuizUseCase getDailyQuizUseCase(GetDailyQuizUseCaseRef ref) {
  return GetDailyQuizUseCase(ref.watch(quizRepositoryProvider));
}

@riverpod
AnswerQuizUseCase answerQuizUseCase(AnswerQuizUseCaseRef ref) {
  return AnswerQuizUseCase(ref.watch(quizRepositoryProvider));
}
