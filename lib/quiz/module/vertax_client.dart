import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
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
      // Remote Config 초기화
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // 설정 가져오기
      await remoteConfig.fetchAndActivate();

      // Base64로 인코딩된 키 가져오기
      final String base64Key = remoteConfig.getString('vertex_ai_key');

      if (base64Key.isEmpty) {
        debugPrint('VertexAI 키를 Remote Config에서 찾을 수 없습니다. 기본 로직 사용');
        throw Exception('VertexAI 키를 Remote Config에서 찾을 수 없습니다');
      }

      // Base64 디코딩
      final String jsonString = utf8.decode(base64.decode(base64Key));
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // 디코딩된 JSON으로 인증 클라이언트 생성
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

      // 실패 시 대체 로직 (개발 모드에서만 작동하도록)
      if (kDebugMode) {
        debugPrint('개발 모드에서 제한된 기능으로 계속합니다.');
        try {
          // 간단한 HTTP 클라이언트만 초기화 (제한된 기능)
          _httpClient = http.Client();
          // 인증 없이 진행 (실제 API 호출은 실패함)
          _initialized = true;
        } catch (fallbackError) {
          debugPrint('대체 로직도 실패: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
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
      final List<String> effectiveSkills =
          skills.isEmpty ? ['프로그래밍 기초'] : skills;

      // 배너용에 맞게 프롬프트 구성 수정
      final prompt = """
      당신은 프로그래밍 퀴즈 생성 전문가입니다. 다음 조건에 맞는 퀴즈를 정확히 JSON 형식으로 생성해주세요:
      
      기술 분야: ${effectiveSkills.join(', ')}
      문제 개수: $questionCount
      난이도: $difficultyLevel
      
      각 질문은 다음 정확한 JSON 구조를 따라야 합니다:
      [
        {
          "question": "문제 내용을 여기에 작성 (명확하고 간결하게)",
          "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
          "correctOptionIndex": 0,
          "explanation": "정답에 대한 간결한 설명 (50단어 내외)",
          "relatedSkill": "${effectiveSkills.first}"
        }
      ]
      
      - 응답은 반드시 올바른 JSON 배열 형식이어야 합니다.
      - 배열의 각 요소는 위에 제시된 모든 키를 포함해야 합니다.
      - 질문들은 $questionCount개 정확히 생성해주세요.
      - 주어진 기술 분야(${effectiveSkills.join(', ')})에 관련된 문제만 출제해주세요.
      - 출제 문제는 실무에서 도움이 될 수 있는 실질적인 내용으로 구성해주세요.
      - 문제와 선택지는 모바일 화면에 표시될 것이므로 간결하게 작성해주세요.
      - 설명은 50단어 내외로 간결하게 작성해주세요.
      
      JSON 배열만 반환하고 다른 텍스트나 설명은 포함하지 마세요.
      """;

      try {
        return await _callVertexAIWithFallback(prompt);
      } catch (e) {
        debugPrint('스킬 기반 퀴즈 생성 실패, 기본 퀴즈 사용: $e');
        // 오류 발생 시 기본 데이터 반환
        final defaultQuiz = _getDefaultQuiz(effectiveSkills.first);
        return [defaultQuiz];
      }
    } catch (e) {
      debugPrint('스킬 기반 퀴즈 생성 실패: $e');
      // 모든 예외 상황에서 기본 퀴즈 반환
      return [_getDefaultQuiz()];
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

      try {
        return await _callVertexAIWithFallback(prompt);
      } catch (e) {
        debugPrint('일반 퀴즈 생성 실패, 기본 퀴즈 사용: $e');
        return [_getDefaultQuiz()];
      }
    } catch (e) {
      debugPrint('일반 퀴즈 생성 실패: $e');
      return [_getDefaultQuiz()];
    }
  }

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

      // API 호출 (인증된 클라이언트가 없는 경우 처리)
      if (!_initialized) {
        debugPrint('API 호출 실패: VertexAI 클라이언트가 초기화되지 않았습니다');
        throw Exception('VertexAI 클라이언트가 초기화되지 않았습니다');
      }

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
          // 디버깅 목적으로 전체 응답 확인 (첫 100자만)
          final responsePreview =
              response.body.length > 100
                  ? response.body.substring(0, 100) + '...'
                  : response.body;
          debugPrint('원본 응답 미리보기: $responsePreview');
          throw Exception('응답 처리 오류: $e');
        }
      } else {
        debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Vertex AI API 호출 실패: $e');
      throw Exception('API 호출 실패: $e');
    }
  }

  // 예외처리 개선: 오류 발생 시 기본 응답 제공
  Future<List<Map<String, dynamic>>> _callVertexAIWithFallback(
    String prompt,
  ) async {
    try {
      return await _callVertexAI(prompt);
    } catch (e) {
      debugPrint('Vertex AI 호출 실패, 기본 퀴즈 사용: $e');
      return [
        // generateQuizBySkills와 generateGeneralQuiz에서 호출하는 형식에 맞게
        // 기본 퀴즈 데이터 구조 맞춤
        {
          "question": "Flutter 앱에서 상태 관리를 위해 사용되지 않는 패키지는?",
          "options": ["Provider", "Riverpod", "MobX", "Django"],
          "correctOptionIndex": 3,
          "explanation": "Django는 Python 웹 프레임워크로, Flutter 상태 관리에 사용되지 않습니다.",
          "relatedSkill": "Flutter",
        },
      ];
    }
  }

  // 기본 퀴즈 제공 메서드 개선 (스킬 기반)
  Map<String, dynamic> _getDefaultQuiz([String? skill]) {
    final defaultQuizzes = [
      {
        "question": "Flutter 앱에서 상태 관리를 위해 사용되지 않는 패키지는?",
        "options": ["Provider", "Riverpod", "MobX", "Django"],
        "correctOptionIndex": 3,
        "explanation": "Django는 Python 웹 프레임워크로, Flutter 상태 관리에 사용되지 않습니다.",
        "category": "Flutter",
      },
      {
        "question": "다음 중 시간 복잡도가 O(n log n)인 정렬 알고리즘은?",
        "options": ["버블 정렬", "퀵 정렬", "삽입 정렬", "선택 정렬"],
        "correctOptionIndex": 1,
        "explanation": "퀵 정렬의 평균 시간 복잡도는 O(n log n)입니다.",
        "category": "알고리즘",
      },
      {
        "question": "Dart에서 불변 객체를 생성하기 위해 주로 사용되는 패키지는?",
        "options": ["immutable.js", "freezed", "immutable", "const_builder"],
        "correctOptionIndex": 1,
        "explanation": "freezed는 Dart에서 불변 객체를 쉽게 생성할 수 있게 해주는 코드 생성 패키지입니다.",
        "category": "Dart",
      },
      {
        "question": "다음 중 React 컴포넌트의 생명주기 메소드가 아닌 것은?",
        "options": [
          "componentDidMount",
          "componentWillUpdate",
          "onRender",
          "render",
        ],
        "correctOptionIndex": 2,
        "explanation":
            "onRender는 React 생명주기 메소드가 아닙니다. 나머지는 모두 React 클래스 컴포넌트의 생명주기 메소드입니다.",
        "category": "React",
      },
      {
        "question": "다음 중 JavaScript의 원시(primitive) 타입이 아닌 것은?",
        "options": ["String", "Number", "Boolean", "Array"],
        "correctOptionIndex": 3,
        "explanation":
            "Array는 객체(Object) 타입이며, JavaScript의 원시 타입에는 String, Number, Boolean, Null, Undefined, Symbol, BigInt가 있습니다.",
        "category": "JavaScript",
      },
    ];

    // 스킬과 관련된 퀴즈 찾기
    if (skill != null && skill.isNotEmpty) {
      final skillLower = skill.toLowerCase();
      debugPrint('스킬 "$skill"에 맞는 기본 퀴즈 찾는 중...');

      final matchingQuizzes =
          defaultQuizzes.where((quiz) {
            final quizSkill = (quiz["category"] as String).toLowerCase();
            return quizSkill.contains(skillLower) ||
                skillLower.contains(quizSkill) ||
                // 특정 스킬과 관련 기술 매핑
                (skillLower.contains('flutter') &&
                    quizSkill.contains('dart')) ||
                (skillLower.contains('dart') &&
                    quizSkill.contains('flutter')) ||
                (skillLower.contains('js') &&
                    quizSkill.contains('javascript')) ||
                (skillLower.contains('frontend') &&
                    (quizSkill.contains('react') ||
                        quizSkill.contains('javascript') ||
                        quizSkill.contains('flutter')));
          }).toList();

      // 매칭되는 퀴즈가 있으면 사용
      if (matchingQuizzes.isNotEmpty) {
        final selectedQuiz = matchingQuizzes.first;
        debugPrint('스킬 "$skill"에 맞는 퀴즈 찾음: ${selectedQuiz["question"]}');
        return {...selectedQuiz}; // 깊은 복사
      }

      debugPrint('스킬 "$skill"에 맞는 퀴즈를 찾지 못함, 랜덤 선택');
    }

    // 매칭되는 퀴즈가 없거나 스킬이 없는 경우 랜덤 선택
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % defaultQuizzes.length;
    debugPrint('랜덤 기본 퀴즈 사용 (인덱스: $randomIndex)');
    return {...defaultQuizzes[randomIndex]}; // 깊은 복사
  }

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _authClient.close();
    }
  }
}
