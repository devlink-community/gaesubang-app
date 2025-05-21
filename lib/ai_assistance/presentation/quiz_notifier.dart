// lib/quiz/presentation/quiz_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/use_case/answer_quiz_use_case.dart';
import '../domain/use_case/get_daily_quiz_usecase.dart';
import '../module/quiz_di.dart';
import 'quiz_action.dart';
import 'quiz_state.dart';

part 'quiz_notifier.g.dart';

@riverpod
class QuizNotifier extends _$QuizNotifier {
  late final GetDailyQuizUseCase _getDailyQuizUseCase;
  late final AnswerQuizUseCase _answerQuizUseCase;

  @override
  QuizState build() {
    _getDailyQuizUseCase = ref.watch(getDailyQuizUseCaseProvider);
    _answerQuizUseCase = ref.watch(answerQuizUseCaseProvider);

    // 초기 상태는 로딩되지 않은 상태
    return const QuizState(quizData: AsyncValue.data(null));
  }

  // 배너 표시 여부 상태 조작
  void showBanner() {
    state = state.copyWith(showBanner: true);
  }

  void hideBanner() {
    state = state.copyWith(showBanner: false);
  }

  // 선택한 답변 인덱스 업데이트
  void updateSelectedAnswer(int? index) {
    state = state.copyWith(selectedAnswerIndex: index);
  }

  // 액션 처리
  Future<void> onAction(QuizAction action) async {
    switch (action) {
      case LoadQuiz(:final skills):
        await _loadQuiz(skills: skills);
        break;

      case SubmitAnswer(:final answerIndex):
        await _submitAnswer(answerIndex);
        break;

      case CloseQuiz():
        hideBanner();
        break;
    }
  }

  // 퀴즈 로드 메서드
  Future<void> _loadQuiz({String? skills}) async {
    // 로깅
    debugPrint('QuizNotifier - 퀴즈 로드 요청, 스킬: "$skills"');

    // 스킬 정보 업데이트
    state = state.copyWith(
      userSkills: skills,
      quizData: const AsyncValue.loading(),
    );

    // 날짜 체크 로직 제거 (하루 한 개 제한 해제)
    // 대신 항상 새 퀴즈를 로드하도록 수정

    // 스킬 전처리 - null이나 빈 문자열 등 처리
    String? processedSkills =
        (skills?.trim().isEmpty ?? true) ? null : skills?.trim();

    try {
      // 퀴즈 로드
      final quizResult = await _getDailyQuizUseCase.execute(
        skills: processedSkills,
      );

      // 결과에 따라 상태 업데이트
      if (quizResult case AsyncData(:final value)) {
        // 성공적으로 로드됨
        state = state.copyWith(
          quizData: AsyncValue.data(value),
          lastQuizLoadDate: DateTime.now(), // 현재 시간으로 업데이트
          selectedAnswerIndex: null, // 선택 답변 초기화
        );
        debugPrint('QuizNotifier - 퀴즈 로드 성공: ${value?.question}');
      } else if (quizResult case AsyncError(:final error, :final stackTrace)) {
        // 오류 발생
        state = state.copyWith(quizData: AsyncValue.error(error, stackTrace));
        debugPrint('QuizNotifier - 퀴즈 로드 오류: $error');
      }
    } catch (e, st) {
      debugPrint('QuizNotifier - 퀴즈 로드 예외 발생: $e');
      state = state.copyWith(quizData: AsyncValue.error(e, st));
    }
  }

  // 답변 제출 메서드
  Future<void> _submitAnswer(int answerIndex) async {
    final currentQuiz = state.quiz;
    if (currentQuiz == null || currentQuiz.isAnswered) {
      debugPrint('QuizNotifier - 답변 제출 취소: 퀴즈 없음 또는 이미 답변함');
      return;
    }

    // 제출 중 상태로 변경
    state = state.copyWith(
      isSubmitting: true,
      selectedAnswerIndex: answerIndex,
    );

    try {
      // 답변 저장
      final result = await _answerQuizUseCase.execute(
        quiz: currentQuiz,
        answerIndex: answerIndex,
      );

      // 결과에 따라 상태 업데이트
      if (result case AsyncData(:final value)) {
        state = state.copyWith(
          quizData: AsyncValue.data(value),
          isSubmitting: false,
        );
        debugPrint(
          'QuizNotifier - 답변 제출 성공: 선택: ${value.attemptedAnswerIndex}',
        );
      } else if (result case AsyncError(:final error, :final stackTrace)) {
        state = state.copyWith(
          quizData: AsyncValue.error(error, stackTrace),
          isSubmitting: false,
        );
        debugPrint('QuizNotifier - 답변 제출 오류: $error');
      }
    } catch (e, st) {
      debugPrint('QuizNotifier - 답변 제출 예외 발생: $e');
      state = state.copyWith(
        quizData: AsyncValue.error(e, st),
        isSubmitting: false,
      );
    }
  }

  // 퀴즈 상태 초기화
  void resetQuiz() {
    state = const QuizState(quizData: AsyncValue.data(null), showBanner: true);
  }
}
