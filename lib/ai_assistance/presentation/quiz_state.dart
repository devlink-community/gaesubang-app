import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/quiz.dart';

part 'quiz_state.freezed.dart';

@freezed
class QuizState with _$QuizState {
  const QuizState({
    this.quizResult = const AsyncData(null),
    this.selectedAnswerIndex,
    this.hasAnswered = false,
  });

  final AsyncValue<Quiz?> quizResult;
  final int? selectedAnswerIndex;
  final bool hasAnswered;
}
