// lib/quiz/presentation/quiz_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/quiz.dart';

part 'quiz_state.freezed.dart';

@freezed
class QuizState with _$QuizState {
  const QuizState({
    // 퀴즈 데이터 (로딩, 성공, 에러 상태 모두 포함)
    this.quizData = const AsyncValue<Quiz?>.loading(),

    // 사용자 스킬 정보 - 퀴즈 생성에 사용
    this.userSkills,

    // 배너 표시 여부
    this.showBanner = true,

    // 선택한 답변 인덱스 (UI 상태)
    this.selectedAnswerIndex,

    // 제출 진행 중 여부
    this.isSubmitting = false,

    // 마지막으로 로드한 퀴즈 날짜 (중복 로드 방지)
    this.lastQuizLoadDate,
  });

  final AsyncValue<Quiz?> quizData;
  final String? userSkills;
  final bool showBanner;
  final int? selectedAnswerIndex;
  final bool isSubmitting;
  final DateTime? lastQuizLoadDate;

  // 편의 메서드는 확장으로 이동
}

// 편의 메서드를 확장으로 구현
extension QuizStateExtension on QuizState {
  bool get isLoading => quizData.isLoading || isSubmitting;
  bool get hasError => quizData.hasError;
  Quiz? get quiz => quizData.valueOrNull;
  bool get isAnswered => quiz?.isAnswered ?? false;
  bool get isQuizCompleted => quiz != null && quiz!.isAnswered;

  // 선택한 답이 맞았는지 여부 확인
  bool get isCorrectAnswer =>
      isAnswered && quiz?.attemptedAnswerIndex == quiz?.correctAnswerIndex;
}
