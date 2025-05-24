import 'dart:math';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/quiz.dart';
import '../repository/quiz_repository.dart';

class GenerateQuizUseCase {
  final QuizRepository _repository;
  final Random _random = Random();

  GenerateQuizUseCase({required QuizRepository repository})
    : _repository = repository;

  Future<AsyncValue<Quiz>> execute(String skillArea) async {
    // 여러 스킬이 있는지 확인하고 있다면 랜덤하게 선택
    final skills = _parseSkills(skillArea);

    // 최대 3개 스킬로 제한
    final limitedSkills = skills.length > 3 ? skills.sublist(0, 3) : skills;

    AppLogger.info(
      '사용 가능한 스킬 (최대 3개): ${limitedSkills.join(", ")}',
      tag: 'QuizGeneration',
    );

    final selectedSkill =
        limitedSkills.isEmpty
            ? '컴퓨터 기초'
            : limitedSkills[_random.nextInt(limitedSkills.length)];

    // 선택된 스킬로 퀴즈 생성 요청
    final cleanSkillArea = _cleanSkillArea(selectedSkill);
    AppLogger.info(
      '선택된 스킬: $cleanSkillArea',
      tag: 'QuizGeneration',
    );

    final result = await _repository.generateQuiz(cleanSkillArea);

    return switch (result) {
      Success(data: final data) => AsyncData(data),
      Error(failure: final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }

  // 스킬 문자열을 목록으로 파싱
  List<String> _parseSkills(String skillArea) {
    if (skillArea.isEmpty) {
      return ['컴퓨터 기초'];
    }

    // 콤마로 구분된 스킬 목록 파싱
    final skills =
        skillArea
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return skills.isEmpty ? ['컴퓨터 기초'] : skills;
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