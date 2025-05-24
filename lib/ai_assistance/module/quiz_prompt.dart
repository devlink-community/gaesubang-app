import 'dart:math';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';

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

    AppLogger.info(
      '퀴즈 프롬프트 생성: 스킬=$cleanSkill, 주제=$selectedTopic, 난이도=$selectedLevel',
      tag: 'QuizPrompt',
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

    AppLogger.info(
      '다중 퀴즈 프롬프트 생성: 스킬=${skills.join(", ")}, 문제 수=$questionCount',
      tag: 'QuizPrompt',
    );

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

  /// 학습 팁 생성 프롬프트 구성 (다양성 대폭 개선)
  String createStudyTipPrompt(String skillArea) {
    final selectedSkill = skillArea.isNotEmpty ? skillArea : '프로그래밍 기초';
    final cleanSkill = cleanSkillArea(selectedSkill);

    // 1. 학습 팁 카테고리 랜덤 선택
    final category = _getRandomCategory();

    // 2. 영어 표현 스타일 랜덤 선택
    final englishStyle = _getRandomEnglishStyle();

    // 3. 프롬프트 템플릿 랜덤 선택
    final template = _getRandomTemplate();

    // 4. 관점/레벨 랜덤 선택
    final perspective = _getRandomPerspective();

    // 5. 고유성을 위한 타임스탬프 및 랜덤 요소
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = _random.nextInt(10000);

    AppLogger.info(
      '학습 팁 프롬프트 생성: 스킬=$cleanSkill, 카테고리=$category, 스타일=$englishStyle, 템플릿=$template, 관점=$perspective',
      tag: 'QuizPrompt',
    );

    // 6. 선택된 템플릿에 따른 프롬프트 생성
    return _buildPromptByTemplate(
      template,
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

  /// 프롬프트 템플릿 랜덤 선택
  String _getRandomTemplate() {
    final templates = [
      '체계적학습형',
      '실무경험형',
      '문제해결형',
      '단계별접근형',
      '비교분석형',
    ];
    return templates[_random.nextInt(templates.length)];
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

  /// 템플릿별 프롬프트 구성
  String _buildPromptByTemplate(
      String template,
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    switch (template) {
      case '체계적학습형':
        return _buildSystematicLearningPrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
      case '실무경험형':
        return _buildPracticalExperiencePrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
      case '문제해결형':
        return _buildProblemSolvingPrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
      case '단계별접근형':
        return _buildStepByStepPrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
      case '비교분석형':
        return _buildComparativeAnalysisPrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
      default:
        return _buildSystematicLearningPrompt(
          skill,
          category,
          englishStyle,
          perspective,
          uniqueId,
          randomSeed,
        );
    }
  }

  /// 체계적 학습형 프롬프트
  String _buildSystematicLearningPrompt(
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    return """
당신은 $skill 분야의 교육 전문가입니다. $perspective에서 $category에 대한 체계적인 학습 가이드를 제공해주세요.

요청 세부사항:
- 기술 분야: $skill
- 학습 카테고리: $category
- 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

학습자가 단계별로 체계적으로 접근할 수 있는 실용적인 팁을 제공해주세요. 
영어 표현은 $englishStyle 스타일로 작성하되, 실제 개발 현장에서 자주 사용되는 표현을 포함해주세요.

결과는 다음 JSON 형식으로 제공:
{
  "title": "체계적 접근을 위한 간결한 제목 (15자 내외)",
  "content": "구체적이고 실용적인 학습 팁 (120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "$englishStyle 스타일의 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 자연스러운 한국어 번역",
  "source": "참고할 만한 출처 (선택사항)"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }

  /// 실무경험형 프롬프트
  String _buildPracticalExperiencePrompt(
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    return """
당신은 $skill 분야에서 실무 경험이 풍부한 시니어 개발자입니다. $perspective에서 $category와 관련된 실무 노하우를 공유해주세요.

요청 세부사항:
- 기술 분야: $skill
- 실무 카테고리: $category
- 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

실제 프로젝트에서 겪을 수 있는 상황을 바탕으로 한 실용적인 조언을 제공해주세요.
영어 표현은 $englishStyle 관점에서 실무진들이 자주 사용하는 표현으로 작성해주세요.

결과는 다음 JSON 형식으로 제공:
{
  "title": "실무 노하우 중심의 제목 (15자 내외)",
  "content": "현장 경험을 바탕으로 한 구체적인 팁 (120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "실무에서 자주 쓰이는 $englishStyle 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 한국어 의미",
  "source": "관련 문서나 레퍼런스 (선택사항)"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }

  /// 문제해결형 프롬프트
  String _buildProblemSolvingPrompt(
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    return """
당신은 $skill 분야의 문제 해결 전문가입니다. $perspective에서 $category 관련 문제를 효과적으로 해결하는 방법을 제시해주세요.

요청 세부사항:
- 기술 분야: $skill
- 문제 유형: $category
- 해결 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

개발자들이 자주 마주치는 문제 상황에 대한 명확하고 실행 가능한 해결책을 제공해주세요.
영어 표현은 $englishStyle 맥락에서 문제 해결 시 사용하는 표현으로 작성해주세요.

결과는 다음 JSON 형식으로 제공:
{
  "title": "문제 해결 중심의 제목 (15자 내외)",
  "content": "명확하고 실행 가능한 해결 방법 (120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "문제 해결 시 사용하는 $englishStyle 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 한국어 해석",
  "source": "참고할 만한 해결책 출처 (선택사항)"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }

  /// 단계별접근형 프롬프트
  String _buildStepByStepPrompt(
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    return """
당신은 $skill 분야의 멘토입니다. $perspective에서 $category를 단계별로 체득할 수 있는 구체적인 로드맵을 제시해주세요.

요청 세부사항:
- 기술 분야: $skill
- 학습 영역: $category
- 멘토링 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

학습자가 첫 번째 단계부터 차근차근 따라갈 수 있는 명확한 가이드라인을 제공해주세요.
영어 표현은 $englishStyle 스타일로 단계별 진행에 도움되는 표현을 포함해주세요.

결과는 다음 JSON 형식으로 제공:
{
  "title": "단계별 접근을 강조한 제목 (15자 내외)",
  "content": "체계적인 단계별 학습 방법 (120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "단계별 진행에 도움되는 $englishStyle 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 한국어 의미",
  "source": "학습 참고 자료 (선택사항)"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }

  /// 비교분석형 프롬프트
  String _buildComparativeAnalysisPrompt(
      String skill,
      String category,
      String englishStyle,
      String perspective,
      int uniqueId,
      int randomSeed,
      ) {
    return """
당신은 $skill 분야의 기술 분석가입니다. $perspective에서 $category와 관련된 다양한 접근법이나 선택지를 비교 분석해주세요.

요청 세부사항:
- 기술 분야: $skill
- 분석 카테고리: $category
- 분석 관점: $perspective
- 영어 표현 스타일: $englishStyle
- 고유 요청 ID: $uniqueId-$randomSeed

서로 다른 옵션들의 장단점을 명확히 비교하여 개발자가 올바른 선택을 할 수 있도록 도와주세요.
영어 표현은 $englishStyle 맥락에서 비교 분석 시 사용하는 표현으로 작성해주세요.
content 는 반드시 한글로. 

결과는 다음 JSON 형식으로 제공:
{
  "title": "비교 분석 중심의 제목 (15자 내외)",
  "content": "장단점을 포함한 명확한 비교 분석을 한글로 표시(120-150자)",
  "relatedSkill": "$skill",
  "englishPhrase": "비교 분석 시 사용하는 $englishStyle 영어 표현 (15단어 이하)",
  "translation": "영어 표현의 한국어 번역",
  "source": "비교 분석 참고 자료 (선택사항)"
}

JSON 형식으로만 응답해주세요.
""".trim();
  }
}