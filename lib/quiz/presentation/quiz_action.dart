import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_action.freezed.dart';

@freezed
sealed class QuizAction with _$QuizAction {
  // 퀴즈 로드 액션 - skills 매개변수 추가
  const factory QuizAction.loadQuiz({String? skills}) = LoadQuiz;

  // 퀴즈 답변 제출 액션
  const factory QuizAction.submitAnswer(int answerIndex) = SubmitAnswer;

  // 퀴즈 닫기 액션
  const factory QuizAction.closeQuiz() = CloseQuiz;
}
