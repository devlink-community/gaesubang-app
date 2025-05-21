import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/quiz.dart';
import '../repository/quiz_repository.dart';

class GenerateQuizUseCase {
  final QuizRepository _repository;

  GenerateQuizUseCase({required QuizRepository repository})
    : _repository = repository;

  Future<AsyncValue<Quiz>> execute(String skillArea) async {
    // 타임스탬프가 포함된 스킬 영역에서 실제 스킬만 추출
    final cleanSkillArea = _cleanSkillArea(skillArea);

    final result = await _repository.generateQuiz(cleanSkillArea);

    return switch (result) {
      Success(data: final data) => AsyncData(data),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }

  // 스킬 영역에서 타임스탬프 제거
  String _cleanSkillArea(String skillArea) {
    // 타임스탬프가 포함된 경우 (형식: "스킬-12345678901234") 처리
    final timestampSeparatorIndex = skillArea.lastIndexOf('-');
    if (timestampSeparatorIndex > 0) {
      final possibleTimestamp = skillArea.substring(
        timestampSeparatorIndex + 1,
      );
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        return skillArea.substring(0, timestampSeparatorIndex);
      }
    }
    return skillArea;
  }
}
