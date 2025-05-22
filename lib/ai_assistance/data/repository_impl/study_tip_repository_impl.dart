// lib/ai_assistance/data/repository_impl/study_tip_repository_impl.dart

import 'dart:math';

import '../../../core/result/result.dart';
import '../../domain/model/study_tip.dart';
import '../../domain/repository/study_tip_repository.dart';
import '../../module/quiz_prompt.dart';
import '../data_source/study_tip_data_source.dart';
import '../dto/study_tip_dto.dart';
import '../mapper/study_tip_mapper.dart';

class StudyTipRepositoryImpl implements StudyTipRepository {
  final StudyTipDataSource _dataSource;
  final PromptService _promptService;
  final Random _random = Random();

  StudyTipRepositoryImpl({
    required StudyTipDataSource dataSource,
    required PromptService promptService,
  }) : _dataSource = dataSource,
        _promptService = promptService;

  @override
  Future<Result<StudyTip>> generateStudyTip(String skillArea) async {
    try {
      // 1. 스킬 파싱 및 랜덤 선택
      final selectedSkill = _selectRandomSkill(skillArea);

      // 2. PromptService를 사용하여 선택된 스킬로 프롬프트 생성
      final prompt = _promptService.createStudyTipPrompt(selectedSkill);

      // 3. 데이터소스를 통한 Firebase AI API 호출
      final response = await _dataSource.generateStudyTipWithPrompt(prompt);

      // 4. DTO로 변환
      final studyTipDto = StudyTipDto.fromJson(response);

      // 5. 모델로 변환하여 반환
      return Result.success(studyTipDto.toModel());
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  /// 콤마로 구분된 스킬 목록에서 랜덤하게 하나 선택
  String _selectRandomSkill(String skillArea) {
    // 빈 문자열 처리
    if (skillArea.isEmpty) {
      return '프로그래밍 기초';
    }

    // 콤마로 구분하여 스킬 목록 파싱
    final skills = skillArea
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => _cleanSkill(s))  // 각 스킬 정제
        .where((s) => s.isNotEmpty)
        .toList();

    // 빈 목록 처리
    if (skills.isEmpty) {
      return '프로그래밍 기초';
    }

    // 랜덤 선택
    final selectedSkill = skills[_random.nextInt(skills.length)];

    // 디버그 로그
    print('StudyTip 스킬 선택: ${skills.join(", ")} 중에서 "$selectedSkill" 선택됨');

    return selectedSkill;
  }

  /// 스킬명 정제 (타임스탬프 제거, 공백 처리 등)
  String _cleanSkill(String skill) {
    // 타임스탬프가 붙어있는 경우 제거 (예: "Flutter-1234567890")
    final timestampIndex = skill.lastIndexOf('-');
    if (timestampIndex > 0) {
      final possibleTimestamp = skill.substring(timestampIndex + 1);
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        skill = skill.substring(0, timestampIndex);
      }
    }

    // 공백 제거 및 기본 정제
    skill = skill.trim();

    // 비정상적인 값 필터링
    if (skill.length > 30 ||
        skill.contains('{') ||
        skill.contains('}') ||
        skill.contains(':') ||
        skill.contains('[') ||
        skill.contains(']')) {
      return '프로그래밍 기초';
    }

    return skill;
  }
}