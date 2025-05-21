import 'package:flutter/foundation.dart';

import '../../module/vertex_client.dart';

abstract interface class VertexAiDataSource {
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt);

  Future<List<Map<String, dynamic>>> generateQuizBySkills(
    List<String> skills,
    int count,
  );

  Future<List<Map<String, dynamic>>> generateGeneralQuiz(int count);
}

class VertexAiDataSourceImpl implements VertexAiDataSource {
  final VertexAIClient _vertexClient;

  VertexAiDataSourceImpl({required VertexAIClient vertexClient})
    : _vertexClient = vertexClient;

  @override
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt) async {
    try {
      // 스킬 영역 추출 (프롬프트에서 추출)
      final String skillArea = _extractSkillAreaFromPrompt(prompt);

      // 단일 퀴즈 생성 메서드 호출
      return await _vertexClient.generateQuiz(skillArea);
    } catch (e) {
      debugPrint('퀴즈 생성 API 호출 실패: $e');
      return _generateFallbackQuiz(prompt);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuizBySkills(
    List<String> skills,
    int count,
  ) async {
    try {
      return await _vertexClient.generateQuizBySkills(skills, count);
    } catch (e) {
      debugPrint('스킬 기반 퀴즈 생성 실패: $e');
      // 폴백: 단일 퀴즈를 여러 개 생성하여 리스트로 반환
      final fallbackQuizzes = <Map<String, dynamic>>[];
      for (int i = 0; i < count; i++) {
        // 스킬 목록이 있으면 스킬 목록에서 랜덤으로 선택, 없으면 기본 스킬 사용
        final skill = skills.isNotEmpty ? skills[i % skills.length] : '컴퓨터 기초';
        fallbackQuizzes.add(_generateFallbackQuiz(skill));
      }
      return fallbackQuizzes;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateGeneralQuiz(int count) async {
    try {
      return await _vertexClient.generateGeneralQuiz(count);
    } catch (e) {
      debugPrint('일반 퀴즈 생성 실패: $e');
      // 폴백: 기본 컴퓨터 지식 퀴즈 여러 개 반환
      final fallbackQuizzes = <Map<String, dynamic>>[];
      for (int i = 0; i < count; i++) {
        fallbackQuizzes.add(_generateFallbackQuiz('컴퓨터 기초'));
      }
      return fallbackQuizzes;
    }
  }

  /// 프롬프트에서 스킬 영역 추출
  String _extractSkillAreaFromPrompt(String prompt) {
    // 타임스탬프 제거 (형식: "스킬-12345678901234")
    final timestampSeparatorIndex = prompt.lastIndexOf('-');
    if (timestampSeparatorIndex > 0) {
      final possibleTimestamp = prompt.substring(timestampSeparatorIndex + 1);
      // 숫자로만 구성된 타임스탬프인지 확인
      if (RegExp(r'^\d+$').hasMatch(possibleTimestamp)) {
        // 타임스탬프 제거 후 스킬만 추출
        prompt = prompt.substring(0, timestampSeparatorIndex).trim();
      }
    }

    // 정규식에서 대소문자 구분 없이 검색
    final skillPattern = RegExp(r'지식 영역: ?([\w\s]+)', caseSensitive: false);
    final match = skillPattern.firstMatch(prompt);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? '';
    }

    // 1. 완전 일치 검사 (대소문자 구분 없이)
    final promptLower = prompt.toLowerCase().trim();

    // 완전히 정확한 매칭을 위한 기술 목록 (소문자로 통일)
    final exactSkills = {
      'python': 'Python',
      'javascript': 'JavaScript',
      'js': 'JavaScript',
      'java': 'Java',
      'flutter': 'Flutter',
      'dart': 'Dart',
      'html': 'HTML',
      'css': 'CSS',
      'c++': 'C++',
      'c#': 'C#',
      'ruby': 'Ruby',
      'php': 'PHP',
      'swift': 'Swift',
      'kotlin': 'Kotlin',
      'go': 'Go',
      'golang': 'Go',
      'rust': 'Rust',
      'typescript': 'TypeScript',
      'ts': 'TypeScript',
      'react': 'React',
      'angular': 'Angular',
      'vue': 'Vue',
      'node.js': 'Node.js',
      'nodejs': 'Node.js',
      'django': 'Django',
      'spring': 'Spring',
      'spring boot': 'Spring Boot',
      'flask': 'Flask',
      'laravel': 'Laravel',
      'express': 'Express',
      'mysql': 'MySQL',
      'postgresql': 'PostgreSQL',
      'mongodb': 'MongoDB',
      'redis': 'Redis',
      'aws': 'AWS',
      'azure': 'Azure',
      'docker': 'Docker',
      'kubernetes': 'Kubernetes',
      'k8s': 'Kubernetes',
      'devops': 'DevOps',
      'git': 'Git',
      'tensorflow': 'TensorFlow',
      'pytorch': 'PyTorch',
      'machine learning': 'Machine Learning',
      'ml': 'Machine Learning',
      'deep learning': 'Deep Learning',
      'dl': 'Deep Learning',
      'ai': 'AI',
      'artificial intelligence': 'AI',
      'data science': 'Data Science',
      'blockchain': 'Blockchain',
      'ios': 'iOS',
      'android': 'Android',
      'web development': 'Web Development',
      'web dev': 'Web Development',
      'frontend': 'Frontend',
      'front-end': 'Frontend',
      'backend': 'Backend',
      'back-end': 'Backend',
      'full stack': 'Full Stack',
      'fullstack': 'Full Stack',
      'ui/ux': 'UI/UX',
      'ui': 'UI/UX',
      'ux': 'UI/UX',
      'unity': 'Unity',
      'unreal engine': 'Unreal Engine',
      'game development': 'Game Development',
      'game dev': 'Game Development',
      'computer science': 'Computer Science',
      'cs': 'Computer Science',
      'algorithm': 'Algorithms',
      'algorithms': 'Algorithms',
      'data structure': 'Data Structures',
      'data structures': 'Data Structures',
    };

    // 완전 일치 검사
    if (exactSkills.containsKey(promptLower)) {
      return exactSkills[promptLower]!;
    }

    // 2. 입력 문자열이 그대로 스킬명인지 확인
    // 외래어/영어인 경우 첫 글자 대문자로 변환
    if (promptLower.isNotEmpty &&
        RegExp(r'^[a-z0-9\s\-\+\/]+$').hasMatch(promptLower)) {
      // 공백으로 구분된 단어들의 첫 글자를 대문자로 변환
      final capitalizedWords = promptLower
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1);
          })
          .join(' ');

      return capitalizedWords;
    }

    // 3. 사용자 입력이 한글이거나 복합어인 경우 그대로 사용
    return prompt.trim();
  }

  /// 폴백 퀴즈 데이터 생성 메서드
  Map<String, dynamic> _generateFallbackQuiz(String prompt) {
    // prompt에서 언급된 스킬에 따라 다른 퀴즈 반환
    if (prompt.toLowerCase().contains('python')) {
      return {
        "question": "Python에서 리스트 컴프리헨션의 주요 장점은 무엇인가요?",
        "options": [
          "메모리 사용량 증가",
          "코드가 더 간결하고 가독성이 좋아짐",
          "항상 더 빠른 실행 속도",
          "버그 방지 기능",
        ],
        "correctOptionIndex": 1,
        "explanation":
            "리스트 컴프리헨션은 반복문과 조건문을 한 줄로 작성할 수 있어 코드가 더 간결해지고 가독성이 향상됩니다.",
        "relatedSkill": "Python",
      };
    } else if (prompt.toLowerCase().contains('flutter') ||
        prompt.toLowerCase().contains('dart')) {
      return {
        "question": "Flutter에서 StatefulWidget과 StatelessWidget의 주요 차이점은 무엇인가요?",
        "options": [
          "StatefulWidget만 빌드 메서드를 가짐",
          "StatelessWidget이 더 성능이 좋음",
          "StatefulWidget은 내부 상태를 가질 수 있음",
          "StatelessWidget은 항상 더 적은 메모리를 사용함",
        ],
        "correctOptionIndex": 2,
        "explanation":
            "StatefulWidget은 내부 상태를 가지고 상태가 변경될 때 UI가 업데이트될 수 있지만, StatelessWidget은 불변이며 내부 상태를 가질 수 없습니다.",
        "relatedSkill": "Flutter",
      };
    }

    // 기본 컴퓨터 기초 퀴즈
    return {
      "question": "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
      "options": ["4비트", "8비트", "16비트", "32비트"],
      "correctOptionIndex": 1,
      "explanation": "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
      "relatedSkill": "컴퓨터 기초",
    };
  }
}
