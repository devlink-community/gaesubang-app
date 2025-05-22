import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/use_case/generate_quiz_use_case.dart';
import '../module/ai_client_di.dart';
import 'quiz_action.dart';
import 'quiz_state.dart';

part 'quiz_notifier.g.dart';

@riverpod
class QuizNotifier extends _$QuizNotifier {
  late final GenerateQuizUseCase _generateQuizUseCase;

  @override
  QuizState build() {
    _generateQuizUseCase = ref.watch(generateQuizUseCaseProvider);
    return const QuizState();
  }

  Future<void> onAction(QuizAction action) async {
    switch (action) {
      case LoadQuiz(:final skills):
        await _loadQuiz(skills);
      case SubmitAnswer(:final answerIndex):
        _submitAnswer(answerIndex);
      case CloseQuiz():
        // 닫기 액션은 UI에서 직접 처리
        break;
    }
  }

  Future<void> _loadQuiz(String? skills) async {
    // 이전 상태를 초기화하고 로딩 상태로 설정
    state = state.copyWith(
      quizResult: const AsyncLoading(),
      selectedAnswerIndex: null,
      hasAnswered: false,
    );

    try {
      final selectedSkill =
          skills
              ?.split(',')
              .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
              .trim() ??
          '컴퓨터 기초';

      // 현재 시간을 추가하여 캐시를 방지 (같은 스킬이라도 항상 새 퀴즈 요청)
      final skillWithTimestamp =
          '$selectedSkill-${DateTime.now().millisecondsSinceEpoch}';

      // UseCase 호출 전 디버그 로그 추가
      print('퀴즈 생성 요청: $skillWithTimestamp');

      final asyncQuiz = await _generateQuizUseCase.execute(skillWithTimestamp);

      // 성공/실패 확인 및 상태 업데이트
      switch (asyncQuiz) {
        case AsyncData(:final value):
          state = state.copyWith(
            quizResult: AsyncData(value),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );
          print('퀴즈 생성 성공: ${value?.question?.substring(0, 20)}...');

        case AsyncError(:final error, :final stackTrace):
          state = state.copyWith(
            quizResult: AsyncError(error, stackTrace),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );
          print('퀴즈 생성 실패: $error');

        case AsyncLoading():
          // 이미 로딩 상태로 설정했으므로 추가 처리 불필요
          break;
      }
    } catch (e, stack) {
      print('퀴즈 생성 예외 발생: $e');
      state = state.copyWith(
        quizResult: AsyncError(e, stack),
        selectedAnswerIndex: null,
        hasAnswered: false,
      );
    }
  }

  void _submitAnswer(int answerIndex) {
    state = state.copyWith(selectedAnswerIndex: answerIndex, hasAnswered: true);
  }

  void resetQuiz() {
    state = state.copyWith(selectedAnswerIndex: null, hasAnswered: false);
  }
}
