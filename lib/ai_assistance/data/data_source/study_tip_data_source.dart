// lib/ai_assistance/data/data_source/study_tip_data_source.dart

import '../../../core/utils/app_logger.dart';
import '../../module/quiz_prompt.dart';
import '../../module/vertex_client.dart';
import 'fallback_service.dart';

abstract interface class StudyTipDataSource {
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt);
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill);
}

class StudyTipDataSourceImpl implements StudyTipDataSource {
  final FirebaseAIClient _firebaseAIClient;
  final FallbackService _fallbackService;
  final PromptService _promptService;

  StudyTipDataSourceImpl({
    required FirebaseAIClient firebaseAIClient,
    required FallbackService fallbackService,
    required PromptService promptService,
  }) : _firebaseAIClient = firebaseAIClient,
       _fallbackService = fallbackService,
       _promptService = promptService;

  @override
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt) async {
    try {
      // Firebase AI SDK를 통한 간단한 호출
      final result = await _firebaseAIClient.callTextModel(prompt);

      AppLogger.info(
        '학습 팁 생성 성공: ${result["title"]}',
        tag: 'StudyTipAI',
      );

      return result;
    } catch (e) {
      AppLogger.error(
        '학습 팁 생성 API 호출 실패',
        tag: 'StudyTipAI',
        error: e,
      );

      // 폴백 서비스 활용
      final skill = _extractSkillFromPrompt(prompt);

      AppLogger.info(
        '폴백 서비스로 학습 팁 생성: $skill',
        tag: 'StudyTipAI',
      );

      return _fallbackService.getFallbackStudyTip(skill);
    }
  }

  @override
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill) async {
    try {
      // 프롬프트 생성 서비스 활용하여 프롬프트 생성
      final prompt = _promptService.createStudyTipPrompt(skill);

      AppLogger.debug(
        '스킬 기반 학습 팁 프롬프트 생성: $skill',
        tag: 'StudyTipAI',
      );

      // 생성된 프롬프트로 API 호출
      return await generateStudyTipWithPrompt(prompt);
    } catch (e) {
      AppLogger.error(
        '스킬 기반 학습 팁 생성 실패',
        tag: 'StudyTipAI',
        error: e,
      );

      AppLogger.info(
        '폴백 서비스로 스킬 기반 학습 팁 생성: $skill',
        tag: 'StudyTipAI',
      );

      return _fallbackService.getFallbackStudyTip(skill);
    }
  }

  /// 프롬프트에서 스킬 영역 추출
  String _extractSkillFromPrompt(String prompt) {
    // 프롬프트 첫 줄에서 스킬 영역 추출 시도
    final firstLine = prompt.split('\n').first.trim();
    final skillPattern = RegExp(r'분야:\s*([^,\n]+)');
    final match = skillPattern.firstMatch(firstLine);

    if (match != null && match.groupCount >= 1) {
      final extractedSkill = match.group(1)?.trim() ?? '프로그래밍 기초';

      AppLogger.debug(
        '프롬프트에서 스킬 추출 성공: $extractedSkill',
        tag: 'SkillExtractor',
      );

      return extractedSkill;
    }

    // 추출 실패 시 기본값 반환
    AppLogger.debug(
      '프롬프트에서 스킬 추출 실패, 기본값 사용: 프로그래밍 기초',
      tag: 'SkillExtractor',
    );

    return '프로그래밍 기초';
  }
}
