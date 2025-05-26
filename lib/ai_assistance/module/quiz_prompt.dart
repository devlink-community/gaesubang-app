import 'dart:math';

import 'package:devlink_mobile_app/core/utils/app_logger.dart';

import '../domain/model/skill_selector.dart';

/// AI 프롬프트 생성을 전담하는 서비스 클래스
/// 모든 프롬프트 생성 로직을 중앙 집중화하여 관리합니다.
class PromptService {
  final Random _random = Random();
  final SkillSelector _skillSelector = SkillSelector(); // SkillSelector 인스턴스

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

  /// 단일 퀴즈 생성을 위한 프롬프트 구성 (모든 주제 대응)
  String createQuizPrompt(String skillArea) {
    // 스킬 확인 및 기본값 설정
    final skill = skillArea.isNotEmpty ? skillArea : '컴퓨터 기초';
    final cleanSkill = cleanSkillArea(skill);

    // 주제 유형 판별
    final topicType = _detectTopicType(cleanSkill);
    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    AppLogger.info(
      '퀴즈 프롬프트 생성: 스킬=$cleanSkill, 주제유형=$topicType',
      tag: 'QuizPrompt',
    );

    // 주제 유형에 따른 프롬프트 생성
    return _buildTopicSpecificPrompt(cleanSkill, topicType, uniqueId);
  }

  /// 주제 유형 판별
  String _detectTopicType(String skill) {
    final programmingKeywords = [
      'java',
      'python',
      'javascript',
      'react',
      'flutter',
      'dart',
      'kotlin',
      'swift',
      'c++',
      'c#',
      'php',
      'ruby',
      'go',
      'rust',
      'typescript',
      '프로그래밍',
      '개발',
      '코딩',
      '알고리즘',
      '자료구조',
      '데이터베이스',
      'api',
      'framework',
      'library',
      '프레임워크',
      '라이브러리',
    ];

    final skillLower = skill.toLowerCase();

    // 프로그래밍 관련 키워드 확인
    for (String keyword in programmingKeywords) {
      if (skillLower.contains(keyword.toLowerCase())) {
        return '프로그래밍';
      }
    }

    // 그 외의 모든 주제
    return '일반';
  }

  /// 주제별 맞춤 프롬프트 생성
  String _buildTopicSpecificPrompt(
    String skill,
    String topicType,
    int uniqueId,
  ) {
    if (topicType == '프로그래밍') {
      return _buildProgrammingPrompt(skill, uniqueId);
    } else {
      return _buildGeneralTopicPrompt(skill, uniqueId);
    }
  }

  /// 프로그래밍 주제 프롬프트
  String _buildProgrammingPrompt(String skill, int uniqueId) {
    final randomTopics = ['개념', '문법', '라이브러리', '프레임워크', '모범 사례', '디자인 패턴'];
    final randomLevels = ['초급', '중급', '입문'];

    final selectedTopic = randomTopics[_random.nextInt(randomTopics.length)];
    final selectedLevel = randomLevels[_random.nextInt(randomLevels.length)];

    return """
당신은 프로그래밍 퀴즈 전문가입니다. 다음 조건으로 완전히 새로운 퀴즈를 생성해주세요:

주제: $skill ($selectedTopic)
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
  "relatedSkill": "$skill"
}

직접적인 설명 없이 JSON 형식으로만 응답해주세요.
""";
  }

  /// 일반 주제 프롬프트 (AI 리서치 기반)
  String _buildGeneralTopicPrompt(String skill, int uniqueId) {
    final questionTypes = ['방법', '효과', '종류', '특징', '원리', '활용법', '주의사항'];
    final difficultyLevels = ['기초', '일반', '심화'];

    final selectedType = questionTypes[_random.nextInt(questionTypes.length)];
    final selectedDifficulty =
        difficultyLevels[_random.nextInt(difficultyLevels.length)];

    return """
당신은 다양한 분야의 지식을 가진 퀴즈 전문가입니다. "$skill"에 대한 퀴즈를 생성해주세요.

주제: $skill
문제 유형: $selectedType
난이도: $selectedDifficulty
고유 ID: $uniqueId

다음 과정을 따라주세요:

1. **리서치 단계**: "$skill"에 대해 깊이 있게 분석하고 관련 지식을 수집해주세요.
   - 해당 주제의 핵심 개념, 방법론, 효과, 특징 등을 파악
   - 실용적이고 유익한 정보 중심으로 리서치
   - 일반인이 알면 도움될 만한 내용 위주로 선별

2. **퀴즈 생성**: 리서치한 내용을 바탕으로 "$selectedType" 유형의 문제를 만들어주세요.
   - 예시: "잠자기" → "숙면을 취하는 가장 효과적인 방법은?"
   - 예시: "운동" → "근력 운동 시 가장 중요한 원리는?"
   - 예시: "요리" → "파스타를 맛있게 삶는 핵심 방법은?"

매번 다른 질문을 반드시 생성해야 합니다. 이전에 생성한 퀴즈와 중복되지 않도록 해주세요.

요구사항:
- $selectedDifficulty 수준의 난이도로 설정
- 4개의 객관식 보기 제공 (그럴듯한 오답 포함)
- 정답과 이유가 포함된 명확한 설명 제공
- 실생활에 도움이 되는 실용적인 내용

결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
{
  "question": "리서치 기반의 구체적인 문제 내용",
  "options": ["보기1", "보기2", "보기3", "보기4"],
  "correctOptionIndex": 0,
  "explanation": "정답의 근거와 추가 정보를 포함한 상세한 설명",
  "relatedSkill": "$skill"
}

직접적인 설명 없이 JSON 형식으로만 응답해주세요.
""";
  }

  /// 스킬 목록 기반으로 다중 퀴즈 생성 프롬프트 구성 (SkillSelector 적용)
  String createMultipleQuizPrompt(
    List<String> skills,
    int questionCount, {
    String difficultyLevel = '중간',
  }) {
    // 스킬 목록이 비어있는 경우 처리
    if (skills.isEmpty) {
      skills = ['프로그래밍 기초'];
    }

    // SkillSelector를 통해 각 스킬 정제 및 분석
    final processedSkills =
        skills
            .map((skill) => _skillSelector.parseSkillString(skill))
            .expand((skillList) => skillList)
            .toSet() // 중복 제거
            .toList();

    // 각 스킬의 주제 유형 분석
    final skillAnalysis =
        processedSkills.map((skill) {
          final topicType = _detectTopicType(skill);
          return {'skill': skill, 'type': topicType};
        }).toList();

    final programmingSkills =
        skillAnalysis
            .where((item) => item['type'] == '프로그래밍')
            .map((item) => item['skill'] as String)
            .toList();

    final generalSkills =
        skillAnalysis
            .where((item) => item['type'] == '일반')
            .map((item) => item['skill'] as String)
            .toList();

    AppLogger.info(
      '다중 퀴즈 프롬프트 생성: 프로그래밍=${programmingSkills.join(", ")}, 일반=${generalSkills.join(", ")}, 문제 수=$questionCount',
      tag: 'QuizPrompt',
    );

    // 혼합 주제용 프롬프트 생성
    return _buildMixedTopicPrompt(
      programmingSkills,
      generalSkills,
      questionCount,
      difficultyLevel,
    );
  }

  /// 혼합 주제 프롬프트 생성
  String _buildMixedTopicPrompt(
    List<String> programmingSkills,
    List<String> generalSkills,
    int questionCount,
    String difficultyLevel,
  ) {
    String skillDescription = '';
    String exampleSection = '';

    if (programmingSkills.isNotEmpty && generalSkills.isNotEmpty) {
      skillDescription = '''
프로그래밍 분야: ${programmingSkills.join(', ')}
일반 분야: ${generalSkills.join(', ')}''';

      exampleSection = '''

문제 생성 가이드라인:
- 프로그래밍 분야: 해당 기술의 개념, 문법, 활용법 등을 다루는 문제
- 일반 분야: 해당 주제에 대해 리서치하여 실용적이고 유익한 정보를 바탕으로 한 문제
  예시) "잠자기" → "숙면을 위한 가장 효과적인 방법은?"
  예시) "운동" → "근력 운동 시 가장 중요한 원리는?"
  예시) "요리" → "파스타를 맛있게 삶는 핵심 방법은?"''';
    } else if (programmingSkills.isNotEmpty) {
      skillDescription = '기술 분야: ${programmingSkills.join(', ')}';
      exampleSection = '\n- 출제 문제는 실무에서 도움이 될 수 있는 실질적인 내용으로 구성해주세요.';
    } else {
      skillDescription = '주제 분야: ${generalSkills.join(', ')}';
      exampleSection = '''

문제 생성 과정:
1. 각 주제에 대해 깊이 있게 리서치하고 관련 지식을 수집
2. 실용적이고 유익한 정보 중심으로 선별
3. 일반인이 알면 도움될 만한 내용으로 퀴즈 구성

예시:
- "잠자기" → "숙면을 위한 가장 효과적인 방법은?"
- "운동" → "근력 운동 시 부상을 방지하는 핵심 원칙은?"
- "요리" → "음식의 맛을 극대화하는 기본 원리는?"''';
    }

    return """
당신은 다양한 분야의 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:

$skillDescription
문제 개수: $questionCount
난이도: $difficultyLevel$exampleSection

각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
[
  {
    "question": "문제 내용을 여기에 작성",
    "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
    "correctOptionIndex": 0,
    "explanation": "정답에 대한 설명",
    "relatedSkill": "관련된 기술 영역 (위 분야 중 하나)"
  }
]

중요 요구사항:
- 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
- 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
- 질문들은 $questionCount개 정확히 생성해주세요.
- relatedSkill 필드는 주어진 분야 중 하나여야 합니다.
- 일반 주제의 경우 해당 분야에 대해 충분히 리서치한 후 실용적인 문제를 출제해주세요.

JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
""";
  }

  /// 일반 컴퓨터 지식 퀴즈 생성 프롬프트 구성
  String createGeneralQuizPrompt(
    int questionCount, {
    String difficultyLevel = '중간',
  }) {
    AppLogger.info(
      '일반 컴퓨터 지식 퀴즈 프롬프트 생성: 문제 수=$questionCount',
      tag: 'QuizPrompt',
    );

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

  /// 학습 팁 생성 프롬프트 구성 (SkillSelector 사용)
  String createStudyTipPrompt(String skillArea) {
    final selectedSkill = skillArea.isNotEmpty ? skillArea : '프로그래밍 기초';

    // SkillSelector를 사용하여 다양성을 고려한 스킬 선택
    final cleanSkill = _skillSelector.selectFromSkillString(selectedSkill);

    // 1. 학습 팁 카테고리 랜덤 선택
    final category = _getRandomCategory();

    // 2. 영어 표현 스타일 랜덤 선택
    final englishStyle = _getRandomEnglishStyle();

    // 3. 관점/레벨 랜덤 선택
    final perspective = _getRandomPerspective();

    // 4. 고유성을 위한 타임스탬프 및 랜덤 요소
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = _random.nextInt(10000);

    AppLogger.info(
      '학습 팁 프롬프트 생성: 스킬=$cleanSkill, 카테고리=$category, 스타일=$englishStyle, 관점=$perspective',
      tag: 'QuizPrompt',
    );

    // 단일 객체 JSON 형태로 통일된 프롬프트 생성
    return _buildUnifiedStudyTipPrompt(
      cleanSkill,
      category,
      englishStyle,
      perspective,
      uniqueId,
      randomSeed,
    );
  }

  /// 학습 팁 카테고리 랜덤 선택
  String _getRandomCategory() {
    final categories = [
      '기초개념',
      '실무활용',
      '면접대비',
      '디버깅기법',
      '성능최적화',
      '라이브러리활용',
      '모범사례',
      '실수방지',
      '코드품질',
      '개발환경',
    ];
    return categories[_random.nextInt(categories.length)];
  }

  /// 영어 표현 스타일 랜덤 선택
  String _getRandomEnglishStyle() {
    final styles = [
      '커뮤니케이션',
      '기술용어',
      '인터뷰표현',
      '축약어',
      '실무표현',
      '문서작성',
      '코드리뷰',
    ];
    return styles[_random.nextInt(styles.length)];
  }

  /// 관점/레벨 랜덤 선택
  String _getRandomPerspective() {
    final perspectives = [
      '초보자관점',
      '중급자관점',
      '고급자관점',
      '프론트엔드관점',
      '백엔드관점',
      '풀스택관점',
      '팀리더관점',
      '실무자관점',
    ];
    return perspectives[_random.nextInt(perspectives.length)];
  }

  // SkillSelector 사용으로 인해 이 메서드는 더 이상 필요하지 않음
  // _selectRandomSkillFromArea 메서드 제거됨
  String _buildUnifiedStudyTipPrompt(
    String skill,
    String category,
    String englishStyle,
    String perspective,
    int uniqueId,
    int randomSeed,
  ) {
    return """
당신은 $skill 분야의 전문가입니다. $perspective에서 $category에 대한 실용적인 학습 가이드를 제공해주세요.

요청 세부사항:
- 기술 분야: $skill
- 학습 카테고리: $category
- 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

개발자가 실제로 활용할 수 있는 구체적이고 실용적인 팁을 제공해주세요.
영어 표현은 $englishStyle 스타일로 작성하되, 실제 개발 현장에서 자주 사용되는 표현을 포함해주세요.

결과는 반드시 다음 JSON 형식으로만 제공해주세요:
{
  "title": "간결하고 명확한 제목 (15자 내외)",
  "content": "구체적이고 실용적인 학습 팁을 한글로 작성 (120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "$englishStyle 스타일의 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 자연스러운 한국어 번역",
  "source": "참고할 만한 출처나 레퍼런스 (선택사항)"
}

- 응답은 반드시 올바른 JSON 객체 형식이어야 합니다.
- JSON 객체만 반환하고 다른 텍스트, 설명, 마크다운 코드블록은 포함하지 마세요.
- content 필드는 반드시 한글로 작성해주세요.
- 모든 문자열 값은 따옴표로 올바르게 감싸주세요.
""".trim();
  }
}
