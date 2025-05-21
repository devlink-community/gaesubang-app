import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/result/result.dart';
import '../../domain/model/quiz.dart';
import '../../domain/repository/quiz_repository.dart';
import '../data_source/quiz_data_source.dart';
import '../dto/quiz_dto.dart';
import '../mapper/quiz_mapper.dart';

class QuizRepositoryImpl implements QuizRepository {
  final VertexAiDataSource _dataSource;
  final Random _random = Random();

  QuizRepositoryImpl({required VertexAiDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Result<Quiz>> generateQuiz(String skillArea) async {
    try {
      debugPrint('퀴즈 생성 시작: 스킬=$skillArea');
      final prompt = _buildPrompt(skillArea);
      final response = await _dataSource.generateQuizWithPrompt(prompt);

      debugPrint('퀴즈 생성 응답 수신: ${response.keys.toList()}');

      // DTO로 변환
      final quizDto = QuizDto.fromJson(response);

      // correctOptionIndex 확인 및 수정
      final correctIndex = _validateCorrectOptionIndex(
        quizDto.correctOptionIndex ?? 0,
        quizDto.options?.length ?? 4,
      );

      // 보정된 DTO 생성 (필요시)
      final validatedDto =
          correctIndex != quizDto.correctOptionIndex
              ? quizDto.copyWith(correctOptionIndex: correctIndex)
              : quizDto;

      // 모델로 변환
      final result = validatedDto.toModel();
      debugPrint(
        '퀴즈 생성 완료: ${result.question.substring(0, min(20, result.question.length))}...',
      );

      return Result.success(result);
    } catch (e, st) {
      debugPrint('퀴즈 생성 실패: $e');
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  String _buildPrompt(String skillArea) {
    final targetSkill = skillArea.isEmpty ? '컴퓨터 기초' : skillArea;

    // 타임스탬프나 랜덤 요소 제거 (이미 클라이언트 쪽에서 추가됨)
    final cleanSkill = _cleanSkillArea(targetSkill);

    // 랜덤 요소 추가 (난이도, 주제 다양화)
    final randomTopics = [
      '개념',
      '문법',
      '라이브러리',
      '프레임워크',
      '모범 사례',
      '디자인 패턴',
      '오류 처리',
      '성능 최적화',
    ];
    final randomLevels = ['초급', '중급', '입문', '기초'];
    final randomFormats = ['문제 해결', '개념 이해', '코드 분석', '결과 예측', '오류 찾기'];

    final selectedTopic = randomTopics[_random.nextInt(randomTopics.length)];
    final selectedLevel = randomLevels[_random.nextInt(randomLevels.length)];
    final selectedFormat = randomFormats[_random.nextInt(randomFormats.length)];

    // 유니크한 시드값 생성 (매번 다른 결과 보장)
    final uniqueId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(10000);

    return '''
당신은 프로그래밍 퀴즈 전문가입니다. 다음 조건으로 완전히 새로운 퀴즈를 생성해주세요:

주제: $cleanSkill ($selectedTopic)
난이도: $selectedLevel
문제 유형: $selectedFormat
고유 ID: $uniqueId

이전에 생성했던 퀴즈와 다른, 완전히 새로운 질문을 생성해야 합니다.

- 문제는 $selectedLevel 수준으로, 해당 영역을 배우는 사람이 풀 수 있는 난이도여야 합니다.
- 4개의 객관식 보기를 제공해주세요.
- 정답과 짧은 설명도 함께 제공해주세요.
- 답변은 무작위로 섞어서 제공하되, 정답이 항상 같은 위치에 오지 않도록 해주세요.

결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
{
  "question": "문제 내용",
  "options": ["보기1", "보기2", "보기3", "보기4"],
  "correctOptionIndex": 0,
  "explanation": "간략한 설명",
  "relatedSkill": "$cleanSkill"
}

직접적인 설명 없이 JSON 형식으로만 응답해주세요.
''';
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

  // correctOptionIndex 값 검증 및 수정
  int _validateCorrectOptionIndex(int index, int optionsLength) {
    if (optionsLength == 0) return 0;

    // 범위 확인 (0 <= index < optionsLength)
    if (index < 0 || index >= optionsLength) {
      debugPrint(
        '유효하지 않은 correctOptionIndex 감지: $index, 옵션 개수: $optionsLength',
      );
      return _random.nextInt(optionsLength); // 랜덤한 유효 인덱스 반환
    }

    return index;
  }
}
