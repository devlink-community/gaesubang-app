import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/quiz.dart';
import '../repository/quiz_repository.dart';

class GetDailyQuizUseCase {
  final QuizRepository _repository;

  GetDailyQuizUseCase(this._repository);

  Future<AsyncValue<Quiz>> execute({String? skills}) async {
    // 1. 오늘의 퀴즈가 있는지 확인
    final todayResult = await _repository.getTodayQuiz(skills: skills);

    switch (todayResult) {
      case Success(:final data):
        // 이미 오늘의 퀴즈가 있으면 반환
        if (data != null) {
          return AsyncData(data);
        }
        // 없으면 새로 생성
        final newQuizResult = await _repository.generateDailyQuiz(
          skills: skills,
        );
        return _processResult(newQuizResult);

      case Error(:final failure):
        // 로컬 저장소 오류, 새 퀴즈 생성 시도
        final newQuizResult = await _repository.generateDailyQuiz(
          skills: skills,
        );
        return _processResult(newQuizResult);
    }
  }

  Future<AsyncValue<Quiz>> _processResult(Result<Quiz> result) async {
    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, StackTrace.current);
    }
  }
}
