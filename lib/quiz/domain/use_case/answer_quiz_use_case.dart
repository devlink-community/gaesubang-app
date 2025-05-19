import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/quiz.dart';
import '../repository/quiz_repository.dart';

class AnswerQuizUseCase {
  final QuizRepository _repository;

  AnswerQuizUseCase(this._repository);

  Future<AsyncValue<Quiz>> execute({
    required Quiz quiz,
    required int answerIndex,
  }) async {
    final result = await _repository.saveQuizAnswer(
      quiz: quiz,
      answerIndex: answerIndex,
    );

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
