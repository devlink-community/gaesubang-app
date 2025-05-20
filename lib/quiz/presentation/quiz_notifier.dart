// lib/quiz/presentation/quiz_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/model/quiz.dart';
import '../domain/use_case/answer_quiz_use_case.dart';
import '../domain/use_case/get_daily_quiz_usecase.dart';
import '../module/quiz_di.dart';
import 'quiz_action.dart';

part 'quiz_notifier.g.dart';

@riverpod
class QuizNotifier extends _$QuizNotifier {
  late final GetDailyQuizUseCase _getDailyQuizUseCase;
  late final AnswerQuizUseCase _answerQuizUseCase;
  bool _showBanner = true;
  // 마지막으로 로드한 스킬 정보 저장
  String? _lastLoadedSkills;

  @override
  AsyncValue<Quiz?> build() {
    _getDailyQuizUseCase = ref.watch(getDailyQuizUseCaseProvider);
    _answerQuizUseCase = ref.watch(answerQuizUseCaseProvider);

    // 초기 상태는 로딩 상태가 아닌 데이터 없음 상태로 변경
    return const AsyncData(null);
  }

  // 배너 표시 여부 상태
  bool get showBanner => _showBanner;

  Future<void> onAction(QuizAction action) async {
    switch (action) {
      case LoadQuiz(:final skills):
        await _loadQuiz(skills: skills);

      case SubmitAnswer(:final answerIndex):
        await _submitAnswer(answerIndex);

      case CloseQuiz():
        _showBanner = false;
        // 상태 변경 명시적 알림
        ref.notifyListeners();
    }
  }

  Future<void> _loadQuiz({String? skills}) async {
    // 로깅
    debugPrint('QuizNotifier - 퀴즈 로드 요청, 스킬: "$skills"');

    // 동일한 스킬로 이미 로드된 경우 중복 로드 방지 (null 처리 주의)
    if (_lastLoadedSkills == skills &&
        state is AsyncData &&
        state.value != null) {
      debugPrint('QuizNotifier - 이미 동일한 스킬로 로드됨, 중복 요청 무시');
      return;
    }

    // 스킬 전처리 - null이나 빈 문자열 등 처리
    String? processedSkills =
        (skills?.trim().isEmpty ?? true) ? null : skills?.trim();

    // 로딩 상태로 변경
    state = const AsyncLoading();

    try {
      // 퀴즈 로드
      final quizResult = await _getDailyQuizUseCase.execute(
        skills: processedSkills,
      );

      // 마지막 로드한 스킬 정보 저장
      _lastLoadedSkills = processedSkills;

      // 상태 업데이트
      state = quizResult;

      // 디버깅
      if (quizResult case AsyncData(:final value)) {
        debugPrint('QuizNotifier - 퀴즈 로드 성공: ${value?.question}');
      } else {
        debugPrint('QuizNotifier - 퀴즈 로드 상태: $quizResult');
      }
    } catch (e) {
      debugPrint('QuizNotifier - 퀴즈 로드 예외 발생: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _submitAnswer(int answerIndex) async {
    final currentQuiz = state.valueOrNull;
    if (currentQuiz == null || currentQuiz.isAnswered) {
      debugPrint('QuizNotifier - 답변 제출 취소: 퀴즈 없음 또는 이미 답변함');
      return;
    }

    // 로딩 상태로 변경
    state = const AsyncLoading();

    try {
      // 답변 저장
      final result = await _answerQuizUseCase.execute(
        quiz: currentQuiz,
        answerIndex: answerIndex,
      );

      // 상태 업데이트
      state = result;

      // 디버깅
      if (result case AsyncData(:final value)) {
        debugPrint(
          'QuizNotifier - 답변 제출 성공: ${value.isAnswered}, 선택: ${value.attemptedAnswerIndex}',
        );
      } else {
        debugPrint('QuizNotifier - 답변 제출 상태: $result');
      }
    } catch (e) {
      debugPrint('QuizNotifier - 답변 제출 예외 발생: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  // 배너 리셋 (다시 표시)
  void resetBanner() {
    if (!_showBanner) {
      _showBanner = true;
      ref.notifyListeners();
    }
  }
}
