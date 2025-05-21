import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/aiplatform/v1.dart' as vertex_ai;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VertexAIClient {
  // 싱글톤 패턴
  static final VertexAIClient _instance = VertexAIClient._internal();

  factory VertexAIClient() => _instance;

  VertexAIClient._internal();

  // GCP 프로젝트 설정
  final String _projectId = 'geasubang-2f372';
  final String _location = 'us-central1';
  final String _modelId = 'gemini-2.0-flash';

  // 초기화 상태
  bool _initialized = false;
  late http.Client _httpClient;
  AutoRefreshingAuthClient? _authClient;

  // 마지막 퀴즈 생성 날짜를 추적하기 위한 변수
  DateTime? _lastQuizGenerationDate;
  Map<String, dynamic>? _dailyQuiz;

  /// API 클라이언트 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Remote Config 초기화
      final remoteConfig = FirebaseRemoteConfig.instance;

      try {
        await remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: Duration.zero, // 배포 환경에서는 1시간 간격
          ),
        );

        // 설정 가져오기
        await remoteConfig.fetchAndActivate();

        // JSON 형식으로 저장된 키 직접 가져오기
        final String jsonString = remoteConfig.getString("gaesubang_ai_key");
        debugPrint(
          'VertexAIClient: Fetched vertex_ai_key (JSON String) from Remote Config (project gaesubang-2f372): "$jsonString"',
        );

        if (jsonString.isEmpty) {
          if (kDebugMode) {
            debugPrint('VertexAI: API 키를 Remote Config에서 찾을 수 없습니다.');
          }
          _initializeFallbackMode();
          return;
        }

        try {
          // JSON 파싱 (이미 JSON 문자열이므로 Base64 디코딩 불필요)
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

          // JSON으로 인증 클라이언트 생성
          final credentials = ServiceAccountCredentials.fromJson(jsonMap);
          _httpClient = http.Client();
          _authClient = await clientViaServiceAccount(credentials, [
            vertex_ai.AiplatformApi.cloudPlatformScope,
          ]);

          _initialized = true;
          if (kDebugMode) {
            debugPrint('VertexAI: 초기화 완료');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('VertexAI: 키 처리 실패: $e');
          }
          _initializeFallbackMode();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('VertexAI: Remote Config 설정 실패: $e');
        }
        _initializeFallbackMode();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VertexAI: 초기화 과정 실패: $e');
      }
      _initializeFallbackMode();
    }
  }

  /// 폴백 모드 초기화 (API 호출은 실패하지만 기본 퀴즈는 제공)
  void _initializeFallbackMode() {
    _httpClient = http.Client();
    _authClient = null; // API 호출 불가능 상태
    _initialized = true; // 초기화는 된 것으로 처리 (폴백 동작 가능)

    if (kDebugMode) {
      debugPrint('VertexAI: 폴백 모드로 초기화됨');
    }
  }

  /// 스킬 기반 퀴즈 생성
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

      // 프롬프트 구성
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
        return [_getDefaultQuiz(effectiveSkills.first)];
      }
    } catch (e) {
      debugPrint('스킬 기반 퀴즈 생성 실패: $e');
      // 모든 예외 상황에서 기본 퀴즈 반환
      return [_getDefaultQuiz()];
    }
  }

  /// 일반 컴퓨터 지식 퀴즈 생성
  Future<List<Map<String, dynamic>>> generateGeneralQuiz(
    int questionCount, {
    String difficultyLevel = '중간',
  }) async {
    try {
      if (!_initialized) await initialize();

      // 프롬프트 구성
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
        // 오류 시 기본 퀴즈 반환
        return [_getDefaultQuiz()];
      }
    } catch (e) {
      // 모든 예외 처리
      return [_getDefaultQuiz()];
    }
  }

  /// Vertex AI API 호출
  Future<List<Map<String, dynamic>>> _callVertexAI(String prompt) async {
    try {
      // API 클라이언트 확인
      if (!_initialized || _authClient == null) {
        debugPrint(
          'VertexAIClient: API 클라이언트가 초기화되지 않았습니다. _initialized: $_initialized, _authClient 존재: ${_authClient != null}',
        );
        throw Exception('API 클라이언트가 초기화되지 않았습니다');
      }

      // API 엔드포인트 구성
      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
      debugPrint('VertexAIClient: API 엔드포인트: $endpoint');

      // 페이로드 구성
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

      debugPrint('VertexAIClient: API 요청 전송 시작');

      // API 호출
      try {
        final response = await _authClient!.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        debugPrint('VertexAIClient: API 응답 수신 - 상태 코드: ${response.statusCode}');

        // 응답 처리
        if (response.statusCode == 200) {
          debugPrint('VertexAIClient: API 응답 성공 (200)');

          // 실패한 경우 응답 전체를 로깅 (개발 모드에서만)
          if (kDebugMode) {
            final responsePreview =
                response.body.length > 100
                    ? response.body.substring(0, 100) + '...'
                    : response.body;
            debugPrint('VertexAIClient: 응답 미리보기: $responsePreview');
          }

          // 응답 파싱
          try {
            final Map<String, dynamic> data = jsonDecode(response.body);

            // 응답 구조 확인
            final candidates = data['candidates'];
            if (candidates == null || candidates.isEmpty) {
              debugPrint('VertexAIClient: 응답에 candidates가 없습니다');
              throw Exception('응답에 candidates가 없습니다');
            }

            final content = candidates[0]['content'];
            if (content == null) {
              debugPrint('VertexAIClient: 응답에 content가 없습니다');
              throw Exception('응답에 content가 없습니다');
            }

            final parts = content['parts'];
            if (parts == null || parts.isEmpty) {
              debugPrint('VertexAIClient: 응답에 parts가 없습니다');
              throw Exception('응답에 parts가 없습니다');
            }

            final String generatedText = parts[0]['text'] ?? '';
            debugPrint('VertexAIClient: 텍스트 응답 길이: ${generatedText.length}');

            // JSON 파싱 (생성된 텍스트에서 JSON 부분 추출)
            final jsonStart = generatedText.indexOf('[');
            final jsonEnd = generatedText.lastIndexOf(']') + 1;

            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonString = generatedText.substring(jsonStart, jsonEnd);
              debugPrint(
                'VertexAIClient: JSON 문자열 추출 성공 (길이: ${jsonString.length})',
              );

              try {
                final List<dynamic> parsedJson = jsonDecode(jsonString);
                debugPrint(
                  'VertexAIClient: JSON 파싱 성공 (항목 수: ${parsedJson.length})',
                );

                return parsedJson
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
              } catch (e) {
                debugPrint('VertexAIClient: JSON 파싱 오류: $e');
                throw Exception('JSON 파싱 오류: $e');
              }
            } else {
              debugPrint(
                'VertexAIClient: JSON 형식을 찾을 수 없음. 전체 텍스트: $generatedText',
              );
              throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
            }
          } catch (e) {
            debugPrint('VertexAIClient: 응답 처리 오류: $e');
            throw Exception('응답 처리 오류: $e');
          }
        } else {
          debugPrint(
            'VertexAIClient: API 호출 실패: ${response.statusCode} ${response.body}',
          );
          throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
        }
      } catch (httpError) {
        debugPrint('VertexAIClient: HTTP 호출 오류: $httpError');
        throw Exception('HTTP 호출 오류: $httpError');
      }
    } catch (e) {
      debugPrint('VertexAIClient: Vertex AI API 호출 실패: $e');
      throw Exception('API 호출 실패: $e');
    }
  }

  /// API 호출 폴백 처리
  Future<List<Map<String, dynamic>>> _callVertexAIWithFallback(
    String prompt,
  ) async {
    try {
      return await _callVertexAI(prompt);
    } catch (e) {
      // 폴백 퀴즈 반환
      return [
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

  /// 기본 퀴즈 제공 메서드
  Map<String, dynamic> _getDefaultQuiz([String? skill]) {
    final defaultQuizzes = [
      // 기존 퀴즈 데이터...
    ];

    // 스킬과 관련된 퀴즈 찾기
    if (skill != null && skill.isNotEmpty) {
      final skillLower = skill.toLowerCase();

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
        return {...matchingQuizzes.first}; // 깊은 복사
      }
    }

    // 매칭되는 퀴즈가 없거나 스킬이 없는 경우 랜덤 선택
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % defaultQuizzes.length;
    return {...defaultQuizzes[randomIndex]}; // 깊은 복사
  }

  /// 리소스 정리
  void dispose() {
    if (_initialized && _authClient != null) {
      _authClient!.close();
    }
    _httpClient.close();
  }
}
