import 'dart:math';
import 'package:flutter/foundation.dart';

/// AI 프롬프트 생성을 전담하는 서비스 클래스
/// 모든 프롬프트 생성 로직을 중앙 집중화하여 관리합니다.
class PromptService {
  final Random _random = Random();

  // 스킬 영역에서 타임스탬프 제거
  String cleanSkillArea(String skillArea) {
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

  /// 단일 퀴즈 생성을 위한 프롬프트 구성
  String createQuizPrompt(String skillArea) {
    // 스킬 확인 및 기본값 설정
    final skill = skillArea.isNotEmpty ? skillArea : '컴퓨터 기초';
    final cleanSkill = cleanSkillArea(skill);

    // 랜덤 요소 추가 (난이도, 주제 다양화)
    final randomTopics = ['개념', '문법', '라이브러리', '프레임워크', '모범 사례', '디자인 패턴'];
    final randomLevels = ['초급', '중급', '입문'];

    final selectedTopic = randomTopics[_random.nextInt(randomTopics.length)];
    final selectedLevel = randomLevels[_random.nextInt(randomLevels.length)];
    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    debugPrint(
      '퀴즈 프롬프트 생성: 스킬=$cleanSkill, 주제=$selectedTopic, 난이도=$selectedLevel',
    );

    // 프롬프트 템플릿 생성
    return """
당신은 프로그래밍 퀴즈 전문가입니다. 다음 조건으로 완전히 새로운 퀴즈를 생성해주세요:

주제: $cleanSkill ($selectedTopic)
난이도: $selectedLevel
고유 ID: $uniqueId

매번 다른 질문을 반드시 생성해야 합니다. 이전에 생성한 퀴즈와 중복되지 않도록 해주세요.

- 문제는 $selectedLevel 수준으로, 해당 영역을 배우는 사람이 풀 수 있는 난이도여야 합니다.
- 4개의 객관식 보기를 제공해주세요.
- 정답과 짧은 설명도 함께 제공해주세요.

결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
{
  "question": "문제 내용",
  "options": ["보기1", "보기2", "보기3", "보기4"],
  "correctOptionIndex": 0,
  "explanation": "간략한 설명",
  "relatedSkill": "$cleanSkill"
}

직접적인 설명 없이 JSON 형식으로만 응답해주세요.
""";
  }

  /// 스킬 목록 기반으로 다중 퀴즈 생성 프롬프트 구성
  String createMultipleQuizPrompt(
    List<String> skills,
    int questionCount, {
    String difficultyLevel = '중간',
  }) {
    // 스킬 목록이 비어있는 경우 처리
    if (skills.isEmpty) {
      skills = ['프로그래밍 기초'];
    }

    debugPrint('다중 퀴즈 프롬프트 생성: 스킬=${skills.join(", ")}, 문제 수=$questionCount');

    // 프롬프트 템플릿 생성
    return """
당신은 프로그래밍 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:

기술 분야: ${skills.join(', ')}
문제 개수: $questionCount
난이도: $difficultyLevel

각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
[
  {
    "question": "문제 내용을 여기에 작성",
    "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
    "correctOptionIndex": 0,
    "explanation": "정답에 대한 설명",
    "relatedSkill": "관련된 기술 영역 (위 기술 분야 중 하나)"
  }
]

- 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
- 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
- 질문들은 $questionCount개 정확히 생성해주세요.
- 주어진 기술 분야(${skills.join(', ')})에 관련된 문제만 출제해주세요.
- relatedSkill 필드는 주어진 기술 분야 중 하나여야 합니다.
- 출제 문제는 실무에서 도움이 될 수 있는 실질적인 내용으로 구성해주세요.

JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
""";
  }

  /// 일반 컴퓨터 지식 퀴즈 생성 프롬프트 구성
  String createGeneralQuizPrompt(
    int questionCount, {
    String difficultyLevel = '중간',
  }) {
    debugPrint('일반 컴퓨터 지식 퀴즈 프롬프트 생성: 문제 수=$questionCount');

    return """
당신은 프로그래밍 및 컴퓨터 기초 지식 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:

분야: 컴퓨터 기초 지식 (알고리즘, 자료구조, 네트워크, 운영체제, 데이터베이스 등)
문제 개수: $questionCount
난이도: $difficultyLevel

각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
[
  {
    "question": "문제 내용을 여기에 작성",
    "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
    "correctOptionIndex": 0,
    "explanation": "정답에 대한 설명",
    "relatedSkill": "관련 분야"
  }
]

- 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
- 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
- 질문들은 $questionCount개 정확히 생성해주세요.
- 출제 문제는 개발자로서 알아야 할 중요한 내용으로 구성해주세요.

JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
""";
  }

  /// 학습 팁 생성 프롬프트 구성
  String createStudyTipPrompt(String skillArea) {
    final selectedSkill = skillArea.isNotEmpty ? skillArea : '프로그래밍 기초';
    final cleanSkill = cleanSkillArea(selectedSkill);

    debugPrint('학습 팁 프롬프트 생성: 스킬=$cleanSkill');

    return """
당신은 개발자를 위한 학습 팁 생성 전문가입니다. $cleanSkill 분야에 관한 학습 팁과 실무 영어 표현을 생성해주세요.

- 팁: 개발자 학습에 도움되는 구체적 내용 (120-150자)
- 요청할 때 마다 항상 새로운 내용을 제공해야 합니다.
- 영어: 해당 분야 개발자들이 실제 사용하는 표현 (15단어 이내)
- 요청할 때 마다 항상 새로운 내용을 제공해야 합니다. 

결과는 다음 JSON 형식으로 제공:
{
  "title": "짧은 팁 제목",
  "content": "구체적인 학습 팁 내용",
  "relatedSkill": "$cleanSkill",
  "englishPhrase": "개발자가 자주 사용하는 영어 표현",
  "translation": "한국어 해석",
  "source": "선택적 출처"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }
}
