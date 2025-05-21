import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/model/quiz.dart';
import '../domain/use_case/generate_quiz_use_case.dart';
import '../module/quiz_di.dart';
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
    state = state.copyWith(quizResult: const AsyncLoading());

    try {
      final selectedSkill =
          skills
              ?.split(',')
              .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
              .trim() ??
          '컴퓨터 기초';

      final asyncQuiz = await _generateQuizUseCase.execute(selectedSkill);

      // 성공/실패 확인
      asyncQuiz.when(
        data: (quiz) {
          state = state.copyWith(
            quizResult: AsyncData(quiz),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );
        },
        error: (error, stackTrace) {
          state = state.copyWith(
            quizResult: AsyncError(error, stackTrace),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );
        },
        loading: () {
          // 이미 AsyncLoading으로 설정했으므로 추가 처리 불필요
        },
      );
    } catch (e, stack) {
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
