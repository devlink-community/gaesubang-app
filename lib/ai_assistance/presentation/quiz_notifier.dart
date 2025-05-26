import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/app_logger.dart';
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

    AppLogger.info(
      'QuizNotifier 초기화 완료',
      tag: 'QuizNotifier',
    );

    return const QuizState();
  }

  Future<void> onAction(QuizAction action) async {
    AppLogger.debug(
      'QuizAction 수신: ${action.runtimeType}',
      tag: 'QuizNotifier',
    );

    switch (action) {
      case LoadQuiz(:final skills):
        await _loadQuiz(skills);
      case SubmitAnswer(:final answerIndex):
        _submitAnswer(answerIndex);
      case CloseQuiz():
        AppLogger.debug(
          '퀴즈 닫기 액션 처리',
          tag: 'QuizNotifier',
        );
        break;
    }
  }

  Future<void> _loadQuiz(String? skills) async {
    final startTime = TimeFormatter.nowInSeoul();

    AppLogger.logStep(1, 4, '퀴즈 로딩 시작');

    // 이전 상태를 초기화하고 로딩 상태로 설정
    state = state.copyWith(
      quizResult: const AsyncLoading(),
      selectedAnswerIndex: null,
      hasAnswered: false,
    );

    try {
      // 스킬 처리 및 캐시 방지 타임스탬프 추가
      AppLogger.logStep(2, 4, '스킬 처리 및 타임스탬프 생성');

      final selectedSkill =
          skills
              ?.split(',')
              .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '컴퓨터 기초')
              .trim() ??
          '컴퓨터 기초';

      // 현재 시간을 추가하여 캐시를 방지 (같은 스킬이라도 항상 새 퀴즈 요청)
      final skillWithTimestamp =
          '$selectedSkill-${TimeFormatter.nowInSeoul().millisecondsSinceEpoch}';

      AppLogger.info(
        '퀴즈 생성 요청: $skillWithTimestamp',
        tag: 'QuizGeneration',
      );

      // UseCase 호출
      AppLogger.logStep(3, 4, 'UseCase 호출 실행');
      final asyncQuiz = await _generateQuizUseCase.execute(skillWithTimestamp);

      // 성공/실패 확인 및 상태 업데이트
      AppLogger.logStep(4, 4, '퀴즈 결과 처리');

      switch (asyncQuiz) {
        case AsyncData(:final value):
          state = state.copyWith(
            quizResult: AsyncData(value),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );

          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('퀴즈 생성 완료', duration);

          AppLogger.info(
            '퀴즈 생성 성공: ${value.question.substring(0, value.question.length > 20 ? 20 : value.question.length)}...',
            tag: 'QuizGeneration',
          );

        case AsyncError(:final error, :final stackTrace):
          state = state.copyWith(
            quizResult: AsyncError(error, stackTrace),
            selectedAnswerIndex: null,
            hasAnswered: false,
          );

          final duration = TimeFormatter.nowInSeoul().difference(startTime);
          AppLogger.logPerformance('퀴즈 생성 실패', duration);

          AppLogger.error(
            '퀴즈 생성 실패',
            tag: 'QuizGeneration',
            error: error,
            stackTrace: stackTrace,
          );

        case AsyncLoading():
          // 이미 로딩 상태로 설정했으므로 추가 처리 불필요
          AppLogger.debug(
            '여전히 로딩 상태입니다',
            tag: 'QuizGeneration',
          );
          break;
      }
    } catch (e, stack) {
      final duration = TimeFormatter.nowInSeoul().difference(startTime);
      AppLogger.logPerformance('퀴즈 생성 예외 발생', duration);

      AppLogger.error(
        '퀴즈 생성 예외 발생',
        tag: 'QuizGeneration',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        quizResult: AsyncError(e, stack),
        selectedAnswerIndex: null,
        hasAnswered: false,
      );
    }
  }

  void _submitAnswer(int answerIndex) {
    AppLogger.info(
      '답변 제출: 선택된 답변 인덱스 = $answerIndex',
      tag: 'QuizAnswer',
    );

    state = state.copyWith(
      selectedAnswerIndex: answerIndex,
      hasAnswered: true,
    );

    AppLogger.logState('Quiz 답변 상태', {
      'selectedAnswerIndex': answerIndex,
      'hasAnswered': true,
    });
  }

  void resetQuiz() {
    AppLogger.info(
      '퀴즈 상태 초기화',
      tag: 'QuizNotifier',
    );

    state = state.copyWith(
      selectedAnswerIndex: null,
      hasAnswered: false,
    );

    AppLogger.logState('Quiz 초기화 상태', {
      'selectedAnswerIndex': null,
      'hasAnswered': false,
    });
  }
}
