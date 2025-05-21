import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VertexAIClient {
  // 싱글톤 패턴
  static final VertexAIClient _instance = VertexAIClient._internal();

  factory VertexAIClient() => _instance;

  VertexAIClient._internal();

  // GCP 프로젝트 설정
  final String _projectId = 'gaesubang-2f372';
  final String _location = 'us-central1';
  final String _modelId = 'gemini-2.0-flash';

  // 초기화 상태
  bool _initialized = false;
  late http.Client _httpClient;

  /// 초기화 메서드
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _httpClient = http.Client();
      _initialized = true;
      debugPrint('Vertex AI 클라이언트 초기화 완료');
    } catch (e) {
      debugPrint('Vertex AI 클라이언트 초기화 실패: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Firebase 인증 토큰 가져오기
  Future<String> _getFirebaseIdToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    try {
      // Firebase ID 토큰 가져오기
      final idToken = await currentUser.getIdToken();
      if (idToken == null) {
        throw Exception('ID 토큰을 가져올 수 없습니다');
      }
      return idToken;
    } catch (e) {
      debugPrint('ID 토큰 가져오기 실패: $e');
      throw Exception('인증 토큰을 가져올 수 없습니다: $e');
    }
  }

  /// 퀴즈 생성 메서드
  Future<Map<String, dynamic>> generateQuiz(String skillArea) async {
    try {
      if (!_initialized) await initialize();

      // 개선된 프롬프트 구성
      final prompt = """
      당신은 프로그래밍 퀴즈 전문가입니다. 다음 지식 영역에 관한 간단한 객관식 퀴즈 문제를 생성해주세요: $skillArea

      - 문제는 초급 수준으로, 해당 영역을 배우는 사람이 풀 수 있는 난이도여야 합니다.
      - 4개의 객관식 보기를 제공해주세요.
      - 정답과 짧은 설명도 함께 제공해주세요.

      결과는 반드시 다음 JSON 형식으로 제공해야 합니다:
      {
        "question": "문제 내용",
        "options": ["보기1", "보기2", "보기3", "보기4"],
        "correctOptionIndex": 0,
        "explanation": "간략한 설명",
        "relatedSkill": "$skillArea"
      }

      직접적인 설명 없이 JSON 형식으로만 응답해주세요.
      """;

      try {
        // Firebase ID 토큰 가져오기
        final idToken = await _getFirebaseIdToken();

        // Gemini API 엔드포인트 사용
        final endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

        // API 요청 본문 구성
        final payload = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
            'topK': 40,
            'topP': 0.95,
          },
        };

        // API 키를 쿼리 파라미터로 전달
        // firebase_options.dart에서 가져온 apiKey 사용
        final apiKey = FirebaseAuth.instance.app.options.apiKey;
        final uri = Uri.parse('$endpoint?key=$apiKey');

        debugPrint('Firebase 인증 토큰으로 API 요청 시작...');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(payload),
        );

        // 응답 처리
        debugPrint('API 응답 상태 코드: ${response.statusCode}');

        if (response.statusCode != 200) {
          debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
          throw Exception('퀴즈 생성에 실패했습니다 (${response.statusCode})');
        }

        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('API 응답 성공: ${response.statusCode}');

        // 응답 구조 확인 및 안전하게 처리
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('응답에 candidates가 없습니다');
        }

        final content = candidates[0]['content'] as Map<String, dynamic>?;
        if (content == null) {
          throw Exception('응답에 content가 없습니다');
        }

        final parts = content['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw Exception('응답에 parts가 없습니다');
        }

        final String generatedText = parts[0]['text'] as String? ?? '';

        // JSON 파싱 (생성된 텍스트에서 JSON 부분 추출)
        final jsonStart = generatedText.indexOf('{');
        final jsonEnd = generatedText.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = generatedText.substring(jsonStart, jsonEnd);

          try {
            final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
            return parsedJson;
          } catch (e) {
            debugPrint('JSON 파싱 오류: $e');
            throw Exception('JSON 파싱 오류: $e');
          }
        } else {
          // 전체 텍스트 출력
          debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $generatedText');
          throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
        }
      } catch (e) {
        debugPrint('Firebase 인증 또는 API 호출 오류: $e');
        throw e;
      }
    } catch (e) {
      debugPrint('Vertex AI 호출 중 예외 발생: $e');
      return _generateFallbackQuiz(skillArea);
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

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _httpClient.close();
      _initialized = false;
    }
  }
}
