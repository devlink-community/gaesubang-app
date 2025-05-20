import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/model/quiz.dart';
import '../domain/use_case/answer_quiz_use_case.dart';
import '../domain/use_case/get_daily_quiz_usecase.dart';
import '../module/quiz_di.dart';
import 'quiz_action.dart';

part 'quiz_notifier.g.dart';

// State 파일 생성 없이 Notifier에서 직접 상태 관리
@riverpod
class QuizNotifier extends _$QuizNotifier {
  late final GetDailyQuizUseCase _getDailyQuizUseCase;
  late final AnswerQuizUseCase _answerQuizUseCase;
  bool _showBanner = true;

  @override
  AsyncValue<Quiz?> build() {
    _getDailyQuizUseCase = ref.watch(getDailyQuizUseCaseProvider);
    _answerQuizUseCase = ref.watch(answerQuizUseCaseProvider);

    // 초기 상태는 로딩 상태
    return const AsyncValue.loading();
  }

  // 배너 표시 여부 상태
  bool get showBanner => _showBanner;

  Future<void> onAction(QuizAction action) async {
    switch (action) {
      case LoadQuiz():
        await _loadQuiz();
        break;

      case SubmitAnswer(:final answerIndex):
        await _submitAnswer(answerIndex);
        break;

      case CloseQuiz():
        _showBanner = false;
        // 상태 업데이트 트리거를 위해 현재 퀴즈 상태를 다시 설정
        state = state;
        break;
    }
  }

  Future<void> _loadQuiz() async {
    // 사용자 스킬 정보 가져오기 (현재 Notifier에서는 간단하게 구현)
    final skills = _getUserSkills();

    // 퀴즈 로딩 상태로 변경
    state = const AsyncValue.loading();

    // 퀴즈 로드
    final quizResult = await _getDailyQuizUseCase.execute(skills: skills);

    // 디버그 로그
    if (quizResult case AsyncData(:final value)) {
      debugPrint('QuizNotifier: 퀴즈 로드 완료 - 답변 상태: ${value?.isAnswered}');
    }

    // 상태 업데이트
    state = quizResult;
  }

  Future<void> _submitAnswer(int answerIndex) async {
    if (state is! AsyncData<Quiz?>) return;
    final quiz = (state as AsyncData<Quiz?>).value;
    if (quiz == null || quiz.isAnswered) return;

    // 로딩 상태로 변경
    state = const AsyncValue.loading();

    // 답변 저장
    final result = await _answerQuizUseCase.execute(
      quiz: quiz,
      answerIndex: answerIndex,
    );

    // 디버그 로그
    if (result case AsyncData(:final value)) {
      debugPrint(
        'QuizNotifier: 답변 제출 완료 - 답변 상태: ${value.isAnswered}, 선택 인덱스: ${value.attemptedAnswerIndex}',
      );
    } else if (result case AsyncError(:final error)) {
      debugPrint('QuizNotifier: 답변 제출 실패 - $error');
    }

    // 상태 업데이트
    state = result;
  }

  // 사용자 스킬 정보 가져오기 (실제로는 Profile 상태에서 가져와야 함)
  String? _getUserSkills() {
    try {
      // 이 부분은 실제 구현에서 다른 provider를 통해 가져와야 함
      // 예: final profileState = ref.read(profileNotifierProvider);
      // return profileState.userProfile.value?.skills;

      // 임시 구현
      return null;
    } catch (e) {
      return null;
    }
  }
}
