import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_source/quiz_dart_source.dart';
import '../data/repository_impl/quiz_repository_impl.dart';
import '../domain/repository/quiz_repository.dart';
import '../domain/use_case/answer_quiz_use_case.dart';
import '../domain/use_case/get_daily_quiz_usecase.dart';
import '../../auth/module/auth_di.dart';

part 'quiz_di.g.dart';

// DataSource Provider - VertexAI 사용
@riverpod
QuizDataSource quizDataSource(Ref ref) {
  // VertexAI 구현체 반환
  return VertexAIQuizDataSourceImpl();
}

// Repository Provider
@riverpod
QuizRepository quizRepository(Ref ref) {
  return QuizRepositoryImpl(
    dataSource: ref.watch(quizDataSourceProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
  );
}

// UseCase Providers
@riverpod
GetDailyQuizUseCase getDailyQuizUseCase(Ref ref) {
  return GetDailyQuizUseCase(ref.watch(quizRepositoryProvider));
}

@riverpod
AnswerQuizUseCase answerQuizUseCase(Ref ref) {
  return AnswerQuizUseCase(ref.watch(quizRepositoryProvider));
}
