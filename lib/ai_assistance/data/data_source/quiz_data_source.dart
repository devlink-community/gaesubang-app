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
    // 간단한 방법: 프롬프트에서 "지식 영역: [영역명]" 패턴 찾기
    final skillPattern = RegExp(r'지식 영역: ?([\w\s]+)');
    final match = skillPattern.firstMatch(prompt);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? '';
    }

    // 프롬프트에서 직접 영역 단어 추출 시도
    final commonSkills = [
      'Python',
      'JavaScript',
      'Java',
      'Flutter',
      'Dart',
      'HTML',
      'CSS',
      'C++',
    ];
    for (final skill in commonSkills) {
      if (prompt.contains(skill)) {
        return skill;
      }
    }

    // 기본값 반환
    return '컴퓨터 기초';
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
