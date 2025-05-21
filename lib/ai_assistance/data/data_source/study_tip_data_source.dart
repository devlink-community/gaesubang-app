// lib/ai_assistance/data/data_source/study_tip_data_source.dart

import 'package:flutter/foundation.dart';
import '../../module/quiz_prompt.dart';
import '../../module/vertex_client.dart';
import 'fallback_service.dart';

abstract interface class StudyTipDataSource {
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt);
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill);
}

class StudyTipDataSourceImpl implements StudyTipDataSource {
  final VertexAIClient _vertexClient;
  final FallbackService _fallbackService;
  final PromptService _promptService;

  StudyTipDataSourceImpl({
    required VertexAIClient vertexClient,
    required FallbackService fallbackService,
    required PromptService promptService,
  }) : _vertexClient = vertexClient,
       _fallbackService = fallbackService,
       _promptService = promptService;

  @override
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt) async {
    try {
      // 직접 호출만 담당
      final result = await _vertexClient.callTextModel(prompt);
      debugPrint('학습 팁 생성 성공: ${result["title"]}');
      return result;
    } catch (e) {
      debugPrint('학습 팁 생성 API 호출 실패: $e');
      // 폴백 서비스 활용
      final skill = _extractSkillFromPrompt(prompt);
      return _fallbackService.getFallbackStudyTip(skill);
    }
  }

  @override
  Future<Map<String, dynamic>> generateStudyTipBySkill(String skill) async {
    try {
      // 프롬프트 생성 서비스 활용하여 프롬프트 생성
      final prompt = _promptService.createStudyTipPrompt(skill);

      // 생성된 프롬프트로 API 호출
      return await generateStudyTipWithPrompt(prompt);
    } catch (e) {
      debugPrint('스킬 기반 학습 팁 생성 실패: $e');
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
      return match.group(1)?.trim() ?? '프로그래밍 기초';
    }

    // 추출 실패 시 기본값 반환
    return '프로그래밍 기초';
  }
}
