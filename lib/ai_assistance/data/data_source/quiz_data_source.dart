import 'package:flutter/foundation.dart';

import '../../module/vertex_client.dart';

abstract interface class VertexAiDataSource {
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt);
}

class VertexAiDataSourceImpl implements VertexAiDataSource {
  final VertexAIClient _vertexClient;

  VertexAiDataSourceImpl({required VertexAIClient vertexClient})
    : _vertexClient = vertexClient;

  @override
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt) async {
    try {
      // Vertex AI Client를 사용하여 퀴즈 생성
      return await _vertexClient.generateQuiz(prompt);
    } catch (e) {
      debugPrint('퀴즈 생성 API 호출 실패: $e');
      return _generateFallbackQuiz(prompt);
    }
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
    } else if (prompt.toLowerCase().contains('javascript') ||
        prompt.toLowerCase().contains('js')) {
      return {
        "question": "JavaScript에서 클로저(Closure)란 무엇인가요?",
        "options": [
          "함수를 선언할 때 사용하는 키워드",
          "외부 함수의 변수에 접근할 수 있는 내부 함수",
          "객체의 메소드를 호출하는 방법",
          "비동기 코드를 처리하는 방식",
        ],
        "correctOptionIndex": 1,
        "explanation":
            "클로저는 함수와 그 함수가 선언된 렉시컬 환경의 조합입니다. 이를 통해 내부 함수는 자신이 선언된 외부 함수의 변수에 접근할 수 있습니다.",
        "relatedSkill": "JavaScript",
      };
    } else if (prompt.toLowerCase().contains('java')) {
      return {
        "question": "Java에서 인터페이스와 추상 클래스의 주요 차이점은 무엇인가요?",
        "options": [
          "인터페이스는 다중 상속을 지원하지만 추상 클래스는 단일 상속만 지원함",
          "추상 클래스는 메소드 구현을 포함할 수 없음",
          "인터페이스는 생성자를 가질 수 있음",
          "추상 클래스는 상수를 선언할 수 없음",
        ],
        "correctOptionIndex": 0,
        "explanation":
            "Java에서 클래스는 하나의 클래스만 상속할 수 있지만(단일 상속), 여러 인터페이스를 구현할 수 있습니다(다중 상속). 추상 클래스는 일부 메소드 구현을 포함할 수 있으며, 인터페이스는 Java 8 이전에는 메소드 구현을 포함할 수 없었습니다.",
        "relatedSkill": "Java",
      };
    } else if (prompt.toLowerCase().contains('html') ||
        prompt.toLowerCase().contains('css')) {
      return {
        "question": "CSS에서 'position: absolute'의 의미는 무엇인가요?",
        "options": [
          "요소가 원래 위치에서 상대적으로 배치됨",
          "요소가 문서의 일반 흐름에서 제거되고 가장 가까운 위치 지정 조상을 기준으로 배치됨",
          "요소가 뷰포트를 기준으로 위치 지정됨",
          "요소가 문서의 일반 흐름을 따름",
        ],
        "correctOptionIndex": 1,
        "explanation":
            "position: absolute를 사용하면 요소는 문서의 일반 흐름에서 제거되고, 가장 가까운 position이 static이 아닌 조상 요소를 기준으로 위치가 결정됩니다. 그런 조상이 없으면 초기 컨테이닝 블록을 기준으로 합니다.",
        "relatedSkill": "CSS",
      };
    } else {
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
}
