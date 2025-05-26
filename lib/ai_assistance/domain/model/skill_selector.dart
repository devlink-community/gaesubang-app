import 'dart:math';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';

/// 스킬 선택과 다양성을 관리하는 전담 클래스
/// 최근 사용한 스킬을 추적하여 반복을 방지하고 다양성을 보장합니다.
class SkillSelector {
  static final SkillSelector _instance = SkillSelector._internal();
  factory SkillSelector() => _instance;
  SkillSelector._internal();

  final Random _random = Random();
  final List<String> _recentlyUsedSkills = [];
  final int _maxRecentSkills = 5; // 최근 5개 스킬은 피하기

  /// 여러 스킬 중에서 다양성을 고려하여 랜덤 선택
  String selectDiverseSkill(List<String> availableSkills) {
    if (availableSkills.isEmpty) {
      return '프로그래밍 기초';
    }

    // 단일 스킬인 경우 바로 반환
    if (availableSkills.length == 1) {
      final selectedSkill = availableSkills.first;
      _updateRecentSkills(selectedSkill);

      AppLogger.info(
        '단일 스킬 선택: "$selectedSkill"',
        tag: 'SkillSelector',
      );

      return selectedSkill;
    }

    // 최근 사용하지 않은 스킬들 필터링
    final unusedSkills =
        availableSkills
            .where((skill) => !_recentlyUsedSkills.contains(skill))
            .toList();

    // 선택할 스킬 목록 결정
    final skillsToChooseFrom =
        unusedSkills.isNotEmpty ? unusedSkills : availableSkills;

    // 랜덤 선택
    final selectedSkill =
        skillsToChooseFrom[_random.nextInt(skillsToChooseFrom.length)];

    // 최근 사용 목록 업데이트
    _updateRecentSkills(selectedSkill);

    AppLogger.info(
      '다양성 고려 스킬 선택: 전체=[${availableSkills.join(", ")}], 사용가능=[${skillsToChooseFrom.join(", ")}], 선택="$selectedSkill"',
      tag: 'SkillSelector',
    );

    return selectedSkill;
  }

  /// 스킬 문자열을 파싱하여 개별 스킬 목록으로 변환
  List<String> parseSkillString(String skillString) {
    if (skillString.isEmpty) {
      return ['프로그래밍 기초'];
    }

    // 먼저 타임스탬프 정리
    final cleanedSkill = _cleanSkillArea(skillString);

    // 여러 스킬이 구분자로 분리되어 있는지 확인
    final separators = [',', ';', '/', '|', '&', '+'];
    List<String> skills = [cleanedSkill];

    for (String separator in separators) {
      if (cleanedSkill.contains(separator)) {
        skills =
            cleanedSkill
                .split(separator)
                .map((skill) => skill.trim())
                .where((skill) => skill.isNotEmpty)
                .toList();
        break;
      }
    }

    AppLogger.info(
      '스킬 파싱 완료: 원본="$skillString" → 파싱된 목록=[${skills.join(", ")}]',
      tag: 'SkillSelector',
    );

    return skills;
  }

  /// 스킬 문자열에서 다양성을 고려한 스킬 선택
  String selectFromSkillString(String skillString) {
    final parsedSkills = parseSkillString(skillString);
    return selectDiverseSkill(parsedSkills);
  }

  /// 최근 사용한 스킬 목록 업데이트
  void _updateRecentSkills(String selectedSkill) {
    // 이미 목록에 있다면 제거 (맨 뒤로 이동시키기 위해)
    _recentlyUsedSkills.remove(selectedSkill);

    // 맨 뒤에 추가
    _recentlyUsedSkills.add(selectedSkill);

    // 최대 개수 초과 시 앞에서부터 제거
    while (_recentlyUsedSkills.length > _maxRecentSkills) {
      _recentlyUsedSkills.removeAt(0);
    }

    AppLogger.debug(
      '최근 사용 스킬 업데이트: [${_recentlyUsedSkills.join(", ")}]',
      tag: 'SkillSelector',
    );
  }

  /// 스킬 영역에서 타임스탬프 제거
  String _cleanSkillArea(String skillArea) {
    // 타임스탬프가 포함된 경우 (형식: "스킬-12345678901234") 처리
    final timestampSeparatorIndex = skillArea.lastIndexOf('-');
    if (timestampSeparatorIndex > 0) {
      final possibleTimestamp = skillArea.substring(
        timestampSeparatorIndex + 1,
      );
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        return skillArea.substring(0, timestampSeparatorIndex).trim();
      }
    }
    return skillArea.trim();
  }

  /// 현재 최근 사용 스킬 목록 조회 (디버깅용)
  List<String> getRecentSkills() {
    return List.unmodifiable(_recentlyUsedSkills);
  }

  /// 최근 사용 스킬 목록 초기화
  void clearRecentSkills() {
    _recentlyUsedSkills.clear();
    AppLogger.info('최근 사용 스킬 목록 초기화', tag: 'SkillSelector');
  }

  /// 특정 스킬이 최근에 사용되었는지 확인
  bool isRecentlyUsed(String skill) {
    return _recentlyUsedSkills.contains(skill);
  }

  /// 사용 통계 로깅
  void logUsageStats() {
    AppLogger.info(
      '스킬 사용 통계: 최근 사용된 스킬 ${_recentlyUsedSkills.length}개 [${_recentlyUsedSkills.join(", ")}]',
      tag: 'SkillSelector',
    );
  }
}
