// lib/ai_assistance/data/repository_impl/study_tip_repository_impl.dart

import 'dart:math';

import '../../../core/result/result.dart';
import '../../../core/utils/app_logger.dart';
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
    final startTime = DateTime.now();

    AppLogger.info(
      'StudyTip 생성 시작: $skillArea',
      tag: 'StudyTipRepository',
    );

    try {
      // 1. 스킬 파싱 및 랜덤 선택
      final selectedSkill = _selectRandomSkill(skillArea);

      AppLogger.info(
        '스킬 선택 완료: $selectedSkill',
        tag: 'StudyTipRepository',
      );

      // 2. PromptService를 사용하여 선택된 스킬로 프롬프트 생성
      final prompt = _promptService.createStudyTipPrompt(selectedSkill);

      AppLogger.debug(
        '프롬프트 생성 완료: ${prompt.substring(0, min(50, prompt.length))}...',
        tag: 'StudyTipRepository',
      );

      // 3. 데이터소스를 통한 Firebase AI API 호출
      final response = await _dataSource.generateStudyTipWithPrompt(prompt);

      // 4. DTO로 변환
      final studyTipDto = StudyTipDto.fromJson(response);

      AppLogger.debug(
        'DTO 변환 완료: ${studyTipDto.title}',
        tag: 'StudyTipRepository',
      );

      // 5. 모델로 변환하여 반환
      final studyTip = studyTipDto.toModel();

      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('StudyTip 생성 성공', duration);

      AppLogger.info(
        'StudyTip 생성 성공: ${studyTip.title}',
        tag: 'StudyTipRepository',
      );

      return Result.success(studyTip);
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.logPerformance('StudyTip 생성 실패', duration);

      AppLogger.error(
        'StudyTip 생성 실패',
        tag: 'StudyTipRepository',
        error: e,
        stackTrace: st,
      );

      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  /// 콤마로 구분된 스킬 목록에서 랜덤하게 하나 선택
  String _selectRandomSkill(String skillArea) {
    AppLogger.debug(
      '스킬 선택 프로세스 시작: $skillArea',
      tag: 'SkillSelector',
    );

    // 빈 문자열 처리
    if (skillArea.isEmpty) {
      AppLogger.info(
        '빈 스킬 영역, 기본값 사용: 프로그래밍 기초',
        tag: 'SkillSelector',
      );
      return '프로그래밍 기초';
    }

    // 콤마로 구분하여 스킬 목록 파싱
    final skills =
        skillArea
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => _cleanSkill(s)) // 각 스킬 정제
            .where((s) => s.isNotEmpty)
            .toList();

    AppLogger.logState('스킬 파싱 결과', {
      '원본': skillArea,
      '파싱된 개수': skills.length,
      '파싱된 목록': skills,
    });

    // 빈 목록 처리
    if (skills.isEmpty) {
      AppLogger.warning(
        '파싱된 스킬이 없음, 기본값 사용: 프로그래밍 기초',
        tag: 'SkillSelector',
      );
      return '프로그래밍 기초';
    }

    // 랜덤 선택
    final selectedSkill = skills[_random.nextInt(skills.length)];

    AppLogger.info(
      'StudyTip 스킬 선택: ${skills.join(", ")} 중에서 "$selectedSkill" 선택됨',
      tag: 'SkillSelector',
    );

    return selectedSkill;
  }

  /// 스킬명 정제 (타임스탬프 제거, 공백 처리 등)
  String _cleanSkill(String skill) {
    final originalSkill = skill;

    AppLogger.debug(
      '스킬 정제 시작: $originalSkill',
      tag: 'SkillCleaner',
    );

    // 타임스탬프가 붙어있는 경우 제거 (예: "Flutter-1234567890")
    final timestampIndex = skill.lastIndexOf('-');
    if (timestampIndex > 0) {
      final possibleTimestamp = skill.substring(timestampIndex + 1);
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        skill = skill.substring(0, timestampIndex);

        AppLogger.debug(
          '타임스탬프 제거: $originalSkill → $skill',
          tag: 'SkillCleaner',
        );
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
      AppLogger.warning(
        '비정상적인 스킬명 감지: $skill → 프로그래밍 기초로 대체',
        tag: 'SkillCleaner',
      );

      return '프로그래밍 기초';
    }

    if (originalSkill != skill) {
      AppLogger.debug(
        '스킬 정제 완료: $originalSkill → $skill',
        tag: 'SkillCleaner',
      );
    }

    return skill;
  }
}
