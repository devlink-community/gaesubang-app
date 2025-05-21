import '../../../core/result/result.dart';
import '../model/quiz.dart';

abstract interface class QuizRepository {
  /// 사용자의 스킬 기반으로 퀴즈를 생성합니다
  Future<Result<Quiz>> generateDailyQuiz({String? skills});

  /// 로컬에 저장된 오늘의 퀴즈를 가져옵니다
  Future<Result<Quiz?>> getTodayQuiz({String? skills});

  /// 사용자가 퀴즈에 답변한 결과를 저장합니다
  Future<Result<Quiz>> saveQuizAnswer({
    required Quiz quiz,
    required int answerIndex,
  });

  Future<String> getQuizStorageKey();
}
