import '../../../core/result/result.dart';
import '../model/quiz.dart';

abstract interface class QuizRepository {
  Future<Result<Quiz>> generateQuiz(String skillArea);
}
