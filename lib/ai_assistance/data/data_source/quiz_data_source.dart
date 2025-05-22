import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../module/quiz_prompt.dart';
import '../../module/vertex_client.dart';
import 'fallback_service.dart';

/// Firebase AI 데이터 소스 인터페이스
abstract interface class FirebaseAiDataSource {
  /// 단일 퀴즈 생성
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt);

  /// 스킬 기반 퀴즈 목록 생성
  Future<List<Map<String, dynamic>>> generateQuizBySkills(
    List<String> skills,
    int count,
  );

  /// 일반 컴퓨터 지식 퀴즈 목록 생성
  Future<List<Map<String, dynamic>>> generateGeneralQuiz(int count);

  /// 학습 팁 생성
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt);
}

/// Firebase AI 데이터 소스 구현
class VertexAiDataSourceImpl implements FirebaseAiDataSource {
  final FirebaseAIClient _firebaseAIClient;
  final FallbackService _fallbackService;
  final PromptService _promptService;

  VertexAiDataSourceImpl({
    required FirebaseAIClient firebaseAIClient,
    required FallbackService fallbackService,
    required PromptService promptService,
  }) : _firebaseAIClient = firebaseAIClient,
       _fallbackService = fallbackService,
       _promptService = promptService;

  @override
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt) async {
    try {
      // Firebase AI SDK를 통한 간단한 호출
      final result = await _firebaseAIClient.callTextModel(prompt);
      debugPrint(
        '퀴즈 생성 성공: ${result["question"]?.toString().substring(0, min(20, result["question"]?.toString().length ?? 0))}...',
      );
      return result;
    } catch (e) {
      debugPrint('퀴즈 생성 API 호출 실패: $e');
      // 폴백 서비스 활용
      final skill = _extractSkillFromPrompt(prompt);
      return _fallbackService.getFallbackQuiz(skill);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuizBySkills(
    List<String> skills,
    int count,
  ) async {
    try {
      // 프롬프트 생성 서비스 활용
      final prompt = _promptService.createMultipleQuizPrompt(skills, count);

      // Firebase AI SDK를 사용한 리스트 호출
      final results = await _firebaseAIClient.callTextModelForList(prompt);
      debugPrint('스킬 기반 퀴즈 생성 성공: ${results.length}개');
      return results;
    } catch (e) {
      debugPrint('스킬 기반 퀴즈 생성 실패: $e');

      // 폴백: 각 스킬에 대해 하나씩 생성
      final fallbackQuizzes = <Map<String, dynamic>>[];
      final targetSkills = skills.isEmpty ? ['컴퓨터 기초'] : skills;

      // 최대 요청 개수만큼 폴백 퀴즈 생성
      for (int i = 0; i < count && i < targetSkills.length; i++) {
        fallbackQuizzes.add(_fallbackService.getFallbackQuiz(targetSkills[i]));
      }

      // 부족한 경우 일반 퀴즈로 채움
      while (fallbackQuizzes.length < count) {
        fallbackQuizzes.add(_fallbackService.getFallbackQuiz('컴퓨터 기초'));
      }

      return fallbackQuizzes;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateGeneralQuiz(int count) async {
    try {
      // 프롬프트 생성 서비스 활용
      final prompt = _promptService.createGeneralQuizPrompt(count);

      // Firebase AI SDK를 사용한 리스트 호출
      final results = await _firebaseAIClient.callTextModelForList(prompt);
      debugPrint('일반 퀴즈 생성 성공: ${results.length}개');
      return results;
    } catch (e) {
      debugPrint('일반 퀴즈 생성 실패: $e');

      // 폴백: 기본 컴퓨터 지식 퀴즈 여러 개 반환
      final fallbackQuizzes = <Map<String, dynamic>>[];
      for (int i = 0; i < count; i++) {
        fallbackQuizzes.add(_fallbackService.getFallbackQuiz('컴퓨터 기초'));
      }
      return fallbackQuizzes;
    }
  }

  @override
  Future<Map<String, dynamic>> generateStudyTipWithPrompt(String prompt) async {
    try {
      // Firebase AI SDK를 통한 간단한 호출
      final result = await _firebaseAIClient.callTextModel(prompt);
      debugPrint('학습 팁 생성 성공: ${result["title"]}');
      return result;
    } catch (e) {
      debugPrint('학습 팁 생성 API 호출 실패: $e');
      // 폴백 서비스 활용
      final skill = _extractSkillFromPrompt(prompt);
      return _fallbackService.getFallbackStudyTip(skill);
    }
  }

  /// 프롬프트에서 스킬 영역 추출
  String _extractSkillFromPrompt(String prompt) {
    // 타임스탬프 제거 후 스킬 추출
    final timestampSeparatorIndex = prompt.lastIndexOf('-');
    if (timestampSeparatorIndex > 0) {
      final possibleTimestamp = prompt.substring(timestampSeparatorIndex + 1);
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        // 타임스탬프 제거 후 스킬만 추출
        prompt = prompt.substring(0, timestampSeparatorIndex).trim();
      }
    }

    // 주제: 스킬명 형태로 되어 있는지 확인
    final skillPattern = RegExp(r'주제:\s*([^()\n]+)');
    final match = skillPattern.firstMatch(prompt);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? '컴퓨터 기초';
    }

    // 기술 분야: 스킬명 형태로 되어 있는지 확인
    final fieldPattern = RegExp(r'기술 분야:\s*([^,\n]+)');
    final fieldMatch = fieldPattern.firstMatch(prompt);
    if (fieldMatch != null && fieldMatch.groupCount >= 1) {
      return fieldMatch.group(1)?.trim() ?? '컴퓨터 기초';
    }

    // 위 패턴이 모두 없으면 첫 줄을 사용
    final firstLine = prompt.split('\n').first.trim();
    if (firstLine.isNotEmpty) {
      return firstLine;
    }

    // 기본값
    return '컴퓨터 기초';
  }
}
