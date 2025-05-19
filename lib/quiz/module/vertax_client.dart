import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/aiplatform/v1.dart' as vertex_ai;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VertexAIClient {
  // 싱글톤 패턴 수정
  static final VertexAIClient _instance = VertexAIClient._internal();
  factory VertexAIClient() => _instance;
  VertexAIClient._internal();

  // GCP 프로젝트 설정
  final String _projectId = 'gaesubang-8904b';
  final String _location = 'global';
  final String _modelId = 'gemini-2.0-flash';

  // 초기화 상태
  bool _initialized = false;
  late http.Client _httpClient;
  late AutoRefreshingAuthClient _authClient;

  // 마지막 퀴즈 생성 날짜를 추적하기 위한 변수
  DateTime? _lastQuizGenerationDate;
  Map<String, dynamic>? _dailyQuiz;

  /// 초기화 메서드
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // 서비스 계정 키 파일 로드
      final String jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final credentials = ServiceAccountCredentials.fromJson(jsonMap);
      _httpClient = http.Client();
      _authClient = await clientViaServiceAccount(credentials, [
        vertex_ai.AiplatformApi.cloudPlatformScope,
      ]);
      _initialized = true;
      debugPrint('Vertex AI 클라이언트 초기화 완료');
    } catch (e) {
      debugPrint('Vertex AI 클라이언트 초기화 실패: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// 매일 하나의 퀴즈 생성 - 배너용 최적화
  Future<Map<String, dynamic>> getDailyQuiz({List<String>? skills}) async {
    try {
      // 오늘 날짜 기준
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 이미 오늘 퀴즈가 생성되었는지 확인
      if (_lastQuizGenerationDate != null &&
          _dailyQuiz != null &&
          _lastQuizGenerationDate!.year == today.year &&
          _lastQuizGenerationDate!.month == today.month &&
          _lastQuizGenerationDate!.day == today.day) {
        debugPrint('이미 오늘 생성된 퀴즈가 있습니다. 캐시된 퀴즈를 반환합니다.');
        return _dailyQuiz!;
      }

      // 새 퀴즈 생성
      debugPrint('오늘의 새 퀴즈를 생성합니다.');
      List<Map<String, dynamic>> quizzes;

      if (skills != null && skills.isNotEmpty) {
        quizzes = await generateQuizBySkills(skills, 1);
      } else {
        quizzes = await generateGeneralQuiz(1);
      }

      // 배너 형식에 맞게 처리
      if (quizzes.isNotEmpty) {
        final quiz = quizzes.first;

        // 필드명 매핑 (VertexAI → 배너 모델)
        final bannerQuiz = {
          'question': quiz['question'],
          'options': quiz['options'],
          'correctAnswerIndex': quiz['correctOptionIndex'] ?? 0, // 기본값 제공
          'explanation': quiz['explanation'],
          'category': quiz['relatedSkill'],
        };

        // 캐시 업데이트
        _dailyQuiz = bannerQuiz;
        _lastQuizGenerationDate = today;

        return bannerQuiz;
      } else {
        throw Exception('퀴즈를 생성할 수 없습니다');
      }
    } catch (e) {
      debugPrint('일일 퀴즈 생성 실패: $e');

      // 오류 시 기본 퀴즈 제공
      return _getDefaultQuiz();
    }
  }

  /// 스킬 기반 퀴즈 생성 - 개선된 버전
  Future<List<Map<String, dynamic>>> generateQuizBySkills(
    List<String> skills,
    int questionCount, {
    String difficultyLevel = '중간',
  }) async {
    try {
      if (!_initialized) await initialize();

      // 디버깅: 스킬 목록 출력
      debugPrint('생성할 퀴즈 스킬 목록: ${skills.join(', ')}');
      debugPrint('스킬 목록 길이: ${skills.length}');

      // 스킬 목록이 비어있는 경우 처리
      if (skills.isEmpty) {
        debugPrint('스킬 목록이 비어 있습니다. 기본 스킬 목록 사용');
        skills = ['Flutter', 'Dart', '프로그래밍 기초']; // 기본 스킬 설정
      }

      // 배너용에 맞게 프롬프트 구성 수정
      final prompt = """
      당신은 프로그래밍 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:
      
      기술 분야: ${skills.join(', ')}
      문제 개수: $questionCount
      난이도: $difficultyLevel
      
      각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
      [
        {
          "question": "문제 내용을 여기에 작성 (명확하고 간결하게)",
          "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
          "correctOptionIndex": 0,
          "explanation": "정답에 대한 간결한 설명 (50단어 내외)",
          "relatedSkill": "${skills.first}"
        }
      ]
      
      - 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
      - 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
      - 질문들은 $questionCount개 정확히 생성해주세요.
      - 주어진 기술 분야(${skills.join(', ')})에 관련된 문제만 출제해주세요.
      - 출제 문제는 실무에서 도움이 될 수 있는 실질적인 내용으로 구성해주세요.
      - 문제와 선택지는 모바일 화면에 표시될 것이므로 간결하게 작성해주세요.
      - 설명은 50단어 내외로 간결하게 작성해주세요.
      
      JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
      """;

      return await _callVertexAI(prompt);
    } catch (e) {
      debugPrint('스킬 기반 퀴즈 생성 실패: $e');
      rethrow;
    }
  }

  /// 일반 컴퓨터 지식 퀴즈 생성 - 개선된 버전
  Future<List<Map<String, dynamic>>> generateGeneralQuiz(
    int questionCount, {
    String difficultyLevel = '중간',
  }) async {
    try {
      if (!_initialized) await initialize();

      // 배너용에 맞게 프롬프트 수정
      final prompt = """
      당신은 프로그래밍 및 컴퓨터 기초 지식 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:
      
      분야: 컴퓨터 기초 지식 (알고리즘, 자료구조, 네트워크, 운영체제, 데이터베이스, 프로그래밍 기초 등)
      문제 개수: $questionCount
      난이도: $difficultyLevel
      
      각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
      [
        {
          "question": "문제 내용을 여기에 작성 (명확하고 간결하게)",
          "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
          "correctOptionIndex": 0,
          "explanation": "정답에 대한 간결한 설명 (50단어 내외)",
          "relatedSkill": "관련 분야"
        }
      ]
      
      - 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
      - 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
      - 질문들은 $questionCount개 정확히 생성해주세요.
      - 출제 문제는 개발자로서 알아야 할 중요한 내용으로 구성해주세요.
      - 문제와 선택지는 모바일 화면에 표시될 것이므로 간결하게 작성해주세요.
      - 설명은 50단어 내외로 간결하게 작성해주세요.
      
      JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
      """;

      return await _callVertexAI(prompt);
    } catch (e) {
      debugPrint('일반 퀴즈 생성 실패: $e');
      rethrow;
    }
  }

  /// Vertex AI API 직접 호출 - 개선된 오류 처리
  Future<List<Map<String, dynamic>>> _callVertexAI(String prompt) async {
    // 기존 코드 유지
    try {
      // 올바른 generateContent API 엔드포인트 구성
      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
      // generateContent API에 맞는 페이로드 구성
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
      // API 호출
      final response = await _authClient.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      // 응답 처리 - 개선된 오류 처리
      if (response.statusCode == 200) {
        // 전체 응답 확인
        debugPrint('API 응답 상태: ${response.statusCode}');
        final Map<String, dynamic> data = jsonDecode(response.body);
        try {
          // 응답 구조 확인 및 안전하게 처리
          final candidates = data['candidates'];
          if (candidates == null || candidates.isEmpty) {
            throw Exception('응답에 candidates가 없습니다');
          }
          final content = candidates[0]['content'];
          if (content == null) {
            throw Exception('응답에 content가 없습니다');
          }
          final parts = content['parts'];
          if (parts == null || parts.isEmpty) {
            throw Exception('응답에 parts가 없습니다');
          }
          final String generatedText = parts[0]['text'] ?? '';
          // JSON 파싱 (생성된 텍스트에서 JSON 부분 추출)
          final jsonStart = generatedText.indexOf('[');
          final jsonEnd = generatedText.lastIndexOf(']') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = generatedText.substring(jsonStart, jsonEnd);
            try {
              final List<dynamic> parsedJson = jsonDecode(jsonString);
              return parsedJson
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
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
          debugPrint('응답 처리 오류: $e');
          // 디버깅 목적으로 전체 응답 확인
          debugPrint('원본 응답: ${response.body}');
          throw Exception('응답 처리 오류: $e');
        }
      } else {
        debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Vertex AI API 호출 실패: $e');
      rethrow;
    }
  }

  // 기본 퀴즈 제공 (오류 시)
  Map<String, dynamic> _getDefaultQuiz() {
    final defaultQuizzes = [
      {
        "question": "Flutter 앱에서 상태 관리를 위해 사용되지 않는 패키지는?",
        "options": ["Provider", "Riverpod", "MobX", "Django"],
        "correctAnswerIndex": 3,
        "explanation": "Django는 Python 웹 프레임워크로, Flutter 상태 관리에 사용되지 않습니다.",
        "category": "Flutter",
      },
      {
        "question": "다음 중 시간 복잡도가 O(n log n)인 정렬 알고리즘은?",
        "options": ["버블 정렬", "퀵 정렬", "삽입 정렬", "선택 정렬"],
        "correctAnswerIndex": 1,
        "explanation": "퀵 정렬의 평균 시간 복잡도는 O(n log n)입니다.",
        "category": "알고리즘",
      },
      {
        "question": "Dart에서 불변 객체를 생성하기 위해 주로 사용되는 패키지는?",
        "options": ["immutable.js", "freezed", "immutable", "const_builder"],
        "correctAnswerIndex": 1,
        "explanation": "freezed는 Dart에서 불변 객체를 쉽게 생성할 수 있게 해주는 코드 생성 패키지입니다.",
        "category": "Dart",
      },
    ];

    return defaultQuizzes[Random().nextInt(defaultQuizzes.length)];
  }

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _authClient.close();
    }
  }
}
