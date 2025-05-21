import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/quiz.dart';
import '../repository/quiz_repository.dart';

class GenerateQuizUseCase {
  final QuizRepository _repository;

  GenerateQuizUseCase({required QuizRepository repository})
    : _repository = repository;

  Future<AsyncValue<Quiz>> execute(String skillArea) async {
    final result = await _repository.generateQuiz(skillArea);

    return switch (result) {
      Success(data: final data) => AsyncData(data),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
