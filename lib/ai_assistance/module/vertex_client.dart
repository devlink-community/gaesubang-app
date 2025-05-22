<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
import 'dart:async'; // Completer 사용을 위해 추가
=======
=======
// lib/ai_assistance/module/vertex_client.dart 개선버전

>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
import 'dart:async';
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
=======
import 'dart:async';
>>>>>>> cc1d0ed3 (충돌 상황 해결)
=======
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)
import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase AI를 사용한 Gemini API 클라이언트
/// 기존 Vertex AI 클라이언트를 대체하여 더 간단하고 효율적인 구조 제공
class FirebaseAIClient {
  // 싱글톤 패턴
  static final FirebaseAIClient _instance = FirebaseAIClient._internal();

  factory FirebaseAIClient() => _instance;

  FirebaseAIClient._internal();

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  // 초기화 상태 관리 개선
=======
  // Random 객체 추가
  final Random _random = Random();

=======
>>>>>>> cc1d0ed3 (충돌 상황 해결)
  // 초기화 상태
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
=======
  // 초기화 상태 관리 개선
>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
  // 초기화 상태
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
  bool _initialized = false;
  bool _initializing = false;

  late GenerativeModel _generativeModel;
  late FirebaseAI _firebaseAI;

<<<<<<< HEAD
<<<<<<< HEAD
=======
  // 캐싱 매커니즘 추가 - 응답 캐시 (메모리 내)
  final Map<String, dynamic> _responseCache = {};

  // 캐시 유효 시간 (24시간)
  final Duration _cacheDuration = const Duration(hours: 24);

  // 캐시 타임스탬프 저장
  final Map<String, DateTime> _cacheTimestamps = {};

>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
  /// 초기화 메서드 개선
=======
  /// 초기화 메서드
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
  Future<void> initialize() async {
    if (_initialized) return;
<<<<<<< HEAD

    if (_initializing) {
      // 초기화가 진행 중인 경우 완료될 때까지 대기
      while (_initializing && !_initialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _initializing = true;

=======
>>>>>>> 65e0a3e8 (quiz: banner 수정:)
    try {
      debugPrint('Firebase AI 클라이언트 초기화 시작');

      // Firebase Auth 확인 (필요 시 익명 로그인)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('Firebase 익명 로그인 완료');
      }

      // Google AI 인스턴스 생성 (무료 tier 사용)
      _firebaseAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);

      // Gemini 모델 생성
      _generativeModel = _firebaseAI.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 1024,
          topK: 40,
          topP: 0.95,
        ),
      );

      _initialized = true;
      _initializing = false;
      debugPrint('Firebase AI 클라이언트 초기화 완료');
    } catch (e) {
      debugPrint('Firebase AI 클라이언트 초기화 실패: $e');
      _initialized = false;
      _initializing = false;
      rethrow;
    }
  }

  /// Remote Config에서 Gemini API 키 로드 (현재는 사용하지 않음 - Firebase Auth 사용)
  Future<String> _loadGeminiApiKey() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      final apiKey = remoteConfig.getString('gemini_ai_key');

      if (apiKey.isEmpty) {
        throw Exception('Gemini API 키가 Remote Config에 없습니다.');
      }

      debugPrint('Remote Config에서 Gemini API 키 로드 완료');
      return apiKey;
    } catch (e) {
      debugPrint('Remote Config에서 Gemini API 키 로드 실패: $e');
      rethrow;
    }
  }

<<<<<<< HEAD
  /// 대체 방법으로 서비스 계정 정보 로드
  Future<Map<String, dynamic>> _loadServiceAccountFromAssets() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      final jsonString = remoteConfig.getString('service_account');
      if (jsonString.isEmpty) throw Exception('Remote Config 키가 비어 있음');

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return jsonMap;
    } catch (e) {
      debugPrint('Remote Config에서 service_account 로드 실패: $e');
      return {};
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  /// LLM API 호출을 위한 통합 메서드 - 새로 추가
=======
  /// 텍스트 생성 API 호출 메서드 - 프롬프트를 받아 JSON 응답 반환
  /// 이 메서드는 프롬프트 내용에 관여하지 않고 API 호출과 응답 처리에만 집중
>>>>>>> cc1d0ed3 (충돌 상황 해결)
=======
  /// 캐시 키 생성 메서드 - 새로 추가
  String _generateCacheKey(String operation, String input) {
    // 간단한 해시 함수 (프로덕션에서는 더 강력한 해시 사용 권장)
    final String normalizedInput = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '$operation:${normalizedInput.hashCode}';
  }

  /// 캐시 체크 메서드 - 새로 추가
  bool _isCacheValid(String key) {
    // 캐시에 없으면 즉시 false 반환
    if (!_responseCache.containsKey(key)) return false;

    // 시간 경과 체크
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final elapsed = now.difference(timestamp);

    return elapsed < _cacheDuration;
  }

  /// 캐시 응답 저장 메서드 - 새로 추가
  void _cacheResponse(String key, dynamic response) {
    _responseCache[key] = response;
    _cacheTimestamps[key] = DateTime.now();

    // 캐시 크기 제한 (최대 50개)
    if (_responseCache.length > 50) {
      // 가장 오래된 항목 찾기
      String? oldestKey;
      DateTime? oldestTime;

      _cacheTimestamps.forEach((k, v) {
        if (oldestTime == null || v.isBefore(oldestTime!)) {
          oldestKey = k;
          oldestTime = v;
        }
      });

      // 오래된 항목 제거
      if (oldestKey != null) {
        _responseCache.remove(oldestKey);
        _cacheTimestamps.remove(oldestKey);
      }
    }
  }

  /// LLM API 호출을 위한 통합 메서드 - 최적화
>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
  /// 텍스트 생성 API 호출 메서드 - 프롬프트를 받아 JSON 응답 반환
  /// 이 메서드는 프롬프트 내용에 관여하지 않고 API 호출과 응답 처리에만 집중
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
=======
  /// 텍스트 생성 API 호출 - 단일 JSON 객체 반환
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)
  Future<Map<String, dynamic>> callTextModel(String prompt) async {
    try {
      if (!_initialized) await initialize();

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      // 기존 엔드포인트 로직 유지
      final endpoint = 'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
=======
      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
>>>>>>> cc1d0ed3 (충돌 상황 해결)
=======
      // 기존 엔드포인트 로직
      final endpoint = 'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)

=======
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)
      // 캐시 방지를 위한 고유 ID 추가
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final enhancedPrompt = '$prompt\n\n요청 ID: $uniqueId';

<<<<<<< HEAD
      // 생성 구성 - 낮은 temperature로 설정 (JSON 형식 응답에 적합)
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$prompt\n\n요청 ID: $uniqueId'},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
<<<<<<< HEAD
<<<<<<< HEAD
          'maxOutputTokens': 1024,
          'topK': 40,
          'topP': 0.95,
        },
      };
=======
      debugPrint(
        'Gemini API 호출 시작: ${prompt.substring(0, min(50, prompt.length))}...',
      );
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)

      // Firebase AI SDK를 사용한 간단한 호출
      final response = await _generativeModel.generateContent([
        Content.text(enhancedPrompt),
      ]);

<<<<<<< HEAD
      // 응답 처리
<<<<<<< HEAD
      if (response.statusCode == 200) {
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

          // 코드 블록 제거
          String cleanedText = generatedText;
          if (cleanedText.contains('```')) {
            cleanedText = cleanedText.replaceAll('```json', '').replaceAll('```', '').trim();
          }

          debugPrint('정제된 텍스트: $cleanedText');

          // JSON 객체 찾기
          final jsonStart = cleanedText.indexOf('{');
          final jsonEnd = cleanedText.lastIndexOf('}') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = cleanedText.substring(jsonStart, jsonEnd);
            try {
              return jsonDecode(jsonString);
            } catch (e) {
              debugPrint('JSON 객체 파싱 오류: $e');
              throw Exception('JSON 객체 파싱 오류: $e');
            }
          } else {
            debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $cleanedText');
            throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
          }
        } catch (e) {
          debugPrint('응답 처리 오류: $e');
          debugPrint('원본 응답: ${response.body}');
          throw Exception('응답 처리 중 오류: $e');
        }
      } else {
        debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
      }
=======
      return _processResponse(response);
>>>>>>> cc1d0ed3 (충돌 상황 해결)
=======
      // 응답 텍스트 추출
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('응답이 비어있습니다');
      }

      debugPrint(
        'Gemini API 응답 수신: ${responseText.substring(0, min(100, responseText.length))}...',
      );

      // JSON 추출 및 반환
      return _extractJsonFromText(responseText);
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)
    } catch (e) {
      debugPrint('Gemini API 호출 실패: $e');
      rethrow;
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
  /// 스킬 기반 퀴즈 생성 - 개선된 버전
=======
  /// 스킬 기반 퀴즈 생성 - 개선된 버전 (기존 코드 유지)
>>>>>>> 65e0a3e8 (quiz: banner 수정:)
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
        skills = ['프로그래밍 기초']; // 기본 스킬 설정
      }

      // 개선된 프롬프트 구성
      final prompt = """
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

      return await _callVertexAIForQuiz(prompt);
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

      // 개선된 프롬프트 구성
      final prompt = """
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
=======
  /// 응답 처리 메서드 (응답에서 JSON 추출)
  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      try {
        // 응답 구조 확인 및 안전하게 처리
        final candidates = data['candidates'];
        if (candidates == null || candidates.isEmpty) {
          throw Exception('응답에 candidates가 없습니다');
>>>>>>> cc1d0ed3 (충돌 상황 해결)
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

        // 코드 블록 제거
        String cleanedText = generatedText;
        if (cleanedText.contains('```')) {
          cleanedText =
              cleanedText
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
        }

        // JSON 객체 찾기
        return _extractJsonFromText(cleanedText);
      } catch (e) {
        debugPrint('응답 처리 오류: $e');
        debugPrint('원본 응답: ${response.body}');
        throw Exception('응답 처리 중 오류: $e');
      }
    } else {
      debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
      throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 텍스트에서 JSON 추출 메서드
  Map<String, dynamic> _extractJsonFromText(String text) {
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}') + 1;

    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      final jsonString = text.substring(jsonStart, jsonEnd);
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        debugPrint('JSON 객체 파싱 오류: $e');
        throw Exception('JSON 객체 파싱 오류: $e');
      }
    } else {
      debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $text');
      throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
    }
  }

  /// 리스트 형태의 JSON 텍스트에서 JSON 배열 추출
  Future<List<Map<String, dynamic>>> callTextModelForList(String prompt) async {
    try {
      if (!_initialized) await initialize();

<<<<<<< HEAD
      // 스킬 확인 및 기본값 설정
      final skill = skillArea.isNotEmpty ? skillArea : '컴퓨터 기초';

      // 랜덤 요소 추가 (난이도, 주제 다양화)
      final randomTopics = ['개념', '문법', '라이브러리', '프레임워크', '모범 사례', '디자인 패턴'];
      final randomLevels = ['초급', '중급', '입문'];

      final selectedTopic = randomTopics[_random.nextInt(randomTopics.length)];
      final selectedLevel = randomLevels[_random.nextInt(randomLevels.length)];
      final uniqueId = DateTime.now().millisecondsSinceEpoch;

      // 타임스탬프 제거 (형식: "스킬-12345678901234")
      final cleanSkill = _cleanSkillArea(skill);

      // 단일 퀴즈 생성을 위한 프롬프트 구성
      final prompt = """
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

      debugPrint('퀴즈 생성 시작: 스킬=$cleanSkill, 고유ID=$uniqueId');

      // 단일 퀴즈 호출 - 10초 타임아웃 추가
      final quizList = await _callVertexAI(prompt).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Vertex AI API 호출 타임아웃 (15초)');
          throw TimeoutException('API 호출이 15초 이내에 완료되지 않았습니다');
        },
      );

<<<<<<< HEAD
      // 단일 퀴즈 호출
      final quizList = await _callVertexAIForQuiz(prompt);
=======
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
      if (quizList.isNotEmpty) {
        return quizList.first;
      } else {
        throw Exception('퀴즈 생성에 실패했습니다');
      }
    } catch (e) {
      debugPrint('단일 퀴즈 생성 실패: $e');

      // 폴백 퀴즈 반환
      return _generateFallbackQuiz(skillArea);
    }
  }

<<<<<<< HEAD
  /// Quiz용 API 호출 메서드
  Future<List<Map<String, dynamic>>> _callVertexAIForQuiz(String prompt) async {
=======
  // 스킬 영역에서 타임스탬프 제거
  String _cleanSkillArea(String skillArea) {
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

  Future<List<Map<String, dynamic>>> _callVertexAI(String prompt) async {
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
    try {
      // 기존 엔드포인트 로직 유지
      final endpoint = 'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
=======
      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';
>>>>>>> cc1d0ed3 (충돌 상황 해결)

      // 각 요청마다 다른 temperature 값 사용하여 다양성 증가
      final random = Random();
      final temperature = 0.5 + random.nextDouble() * 0.4; // 0.5~0.9 사이의 랜덤 값

      // 요청마다 고유한 ID 추가 (캐시 방지)
      final uniqueId = DateTime.now().millisecondsSinceEpoch;

      // 페이로드 구성
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$prompt\n\n요청 ID: $uniqueId'},
            ],
          },
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': 1024,
=======
          'maxOutputTokens': 800, // 토큰 수 적절히 감소
>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
          'maxOutputTokens': 1024,
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
          'topK': 40,
          'topP': 0.95,
        },
      };

      // API 호출 (최대 15초 타임아웃)
      final response = await _authClient
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

<<<<<<< HEAD
<<<<<<< HEAD
      // 응답 처리
<<<<<<< HEAD
=======
      // 응답 처리 - 코드는 기존과 동일하게 유지
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
      if (response.statusCode == 200) {
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

<<<<<<< HEAD
          // 코드 블록 제거
          String cleanedText = generatedText;
          if (cleanedText.contains('```')) {
            cleanedText = cleanedText.replaceAll('```json', '').replaceAll('```', '').trim();
          }

          // JSON 배열 찾기 (Quiz는 주로 배열 형태)
          final jsonStart = cleanedText.indexOf('[');
          final jsonEnd = cleanedText.lastIndexOf(']') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = cleanedText.substring(jsonStart, jsonEnd);

            try {
              final List<dynamic> parsedJson = jsonDecode(jsonString);
              return parsedJson
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            } catch (e) {
              debugPrint('JSON 배열 파싱 오류: $e');
              // 단일 객체 확인 (배열 파싱 실패시)
              return _tryParseAsObject(cleanedText);
            }
          } else {
            // 배열이 없으면 객체로 시도
            return _tryParseAsObject(cleanedText);
=======
          // JSON 파싱 (생성된 텍스트에서 JSON 부분 추출)
          final jsonStart = generatedText.indexOf('{');
          final jsonEnd = generatedText.lastIndexOf('}') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            try {
              final Map<String, dynamic> parsedJson = jsonDecode(
                generatedText.substring(jsonStart, jsonEnd),
              );

              debugPrint(
                '퀴즈 파싱 성공: 문제=${parsedJson['question']?.toString().substring(0, min(20, parsedJson['question']?.toString().length ?? 0))}...',
              );

              return [parsedJson]; // 단일 객체를 리스트로 반환
            } catch (e) {
              // 배열 형태 확인
              final arrayStart = generatedText.indexOf('[');
              final arrayEnd = generatedText.lastIndexOf(']') + 1;

              if (arrayStart >= 0 && arrayEnd > arrayStart) {
                try {
                  final List<dynamic> parsedArray = jsonDecode(
                    generatedText.substring(arrayStart, arrayEnd),
                  );
                  return parsedArray
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();
                } catch (e) {
                  debugPrint('JSON 배열 파싱 오류: $e');
                  throw Exception('JSON 배열 파싱 오류: $e');
                }
              } else {
                debugPrint('JSON 객체 파싱 오류: $e');
                throw Exception('JSON 객체 파싱 오류: $e');
              }
            }
          } else {
            debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $generatedText');
            throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
          }
        } catch (e) {
          debugPrint('응답 처리 오류: $e');
          debugPrint('원본 응답: ${response.body}');
<<<<<<< HEAD

          // 폴백 반환
          return [
            {
              "question": "API 응답 처리 중 오류가 발생했습니다. 다음 중 API 오류 해결 방법으로 적절한 것은?",
              "options": [
                "API 응답 구조 확인",
                "네트워크 연결 확인",
                "서비스 계정 권한 확인",
                "모든 위 항목",
              ],
              "correctOptionIndex": 3,
              "explanation": "API 오류를 해결하기 위해서는 응답 구조, 네트워크 연결, 권한 확인 등 여러 방면의 점검이 필요합니다.",
              "relatedSkill": "API 디버깅",
            },
          ];
=======
          return [_generateFallbackQuiz(prompt)];
>>>>>>> 22afa4f8 (fix: 프롬프트 수정)
        }
      } else {
        debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
      }
=======
      // 응답 처리
<<<<<<< HEAD
      return _processListResponse(response);
>>>>>>> cc1d0ed3 (충돌 상황 해결)
    } catch (e) {
      debugPrint('Vertex AI API 리스트 호출 실패: $e');
      rethrow;
    }
  }

<<<<<<< HEAD
  // 객체 파싱 시도 헬퍼 메서드 - 수정됨
  List<Map<String, dynamic>> _tryParseAsObject(String text) {
    final objectStart = text.indexOf('{');
    final objectEnd = text.lastIndexOf('}') + 1;

    if (objectStart >= 0 && objectEnd > objectStart) {
      final objectString = text.substring(objectStart, objectEnd);
      try {
        final Map<String, dynamic> parsedObject = jsonDecode(objectString);
        return [parsedObject]; // 단일 객체를 리스트로 반환
      } catch (e) {
        debugPrint('JSON 객체 파싱 오류: $e');
        return [_generateFallbackQuiz('')]; // 폴백 퀴즈 반환
      }
    } else {
      debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $text');
      return [_generateFallbackQuiz('')]; // 폴백 퀴즈 반환
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
    }

    // 기본 컴퓨터 기초 퀴즈
    return {
      "question": "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
      "options": ["4비트", "8비트", "16비트", "32비트"],
      "correctOptionIndex": 1,
      "explanation": "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
      "relatedSkill": "컴퓨터 기초",
    };
=======
  /// 리스트 응답 처리 메서드
  Future<List<Map<String, dynamic>>> _processListResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      try {
        // 응답 구조 확인
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

        // 코드 블록 제거
        String cleanedText = generatedText;
        if (cleanedText.contains('```')) {
          cleanedText =
              cleanedText
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
        }

        // JSON 배열 추출
        return _extractJsonArrayFromText(cleanedText);
      } catch (e) {
        debugPrint('응답 처리 오류: $e');
        debugPrint('원본 응답: ${response.body}');
        throw Exception('응답 처리 중 오류: $e');
      }
    } else {
      debugPrint('API 호출 실패: ${response.statusCode} ${response.body}');
      throw Exception('API 호출 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 텍스트에서 JSON 배열 추출 메서드
  List<Map<String, dynamic>> _extractJsonArrayFromText(String text) {
    // 먼저 배열 형태 확인
    final arrayStart = text.indexOf('[');
    final arrayEnd = text.lastIndexOf(']') + 1;

    if (arrayStart >= 0 && arrayEnd > arrayStart) {
      try {
        final List<dynamic> parsedArray = jsonDecode(
          text.substring(arrayStart, arrayEnd),
        );
        return parsedArray
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (e) {
        debugPrint('JSON 배열 파싱 오류: $e');
        // 배열 파싱 실패 시, 단일 객체 확인
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          try {
            final Map<String, dynamic> parsedJson = jsonDecode(
              text.substring(jsonStart, jsonEnd),
            );
            return [parsedJson]; // 단일 객체를 리스트로 반환
          } catch (e) {
            debugPrint('단일 JSON 객체 파싱도 실패: $e');
            throw Exception('JSON 객체 파싱 오류: $e');
          }
        } else {
          throw Exception('JSON 배열 파싱 오류: $e');
        }
      }
    } else {
      // 배열을 찾을 수 없는 경우, 단일 객체 확인
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
=======
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
        try {
          // 응답 구조 처리
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

          // 코드 블록 제거 처리 개선
          String cleanedText = generatedText;
          if (cleanedText.contains('```')) {
            // 모든 코드 블록 표식 효과적 제거
            cleanedText = cleanedText.replaceAll(RegExp(r'```(?:json|dart|javascript|js)?'), '').trim();
          }

          // JSON 객체 찾기 (정규식 활용으로 개선)
          final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
          final match = jsonRegex.firstMatch(cleanedText);

          if (match != null) {
            final jsonString = match.group(0)!;
            try {
              final Map<String, dynamic> result = jsonDecode(jsonString);

              // 캐시에 저장
              _cacheResponse(cacheKey, result);

              return result;
            } catch (e) {
              debugPrint('JSON 객체 파싱 오류: $e');
              throw Exception('JSON 객체 파싱 오류: $e');
            }
          } else {
            debugPrint('JSON 형식을 찾을 수 없음');
            throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
          }
        } catch (e) {
          debugPrint('응답 처리 오류: $e');
          throw Exception('응답 처리 중 오류: $e');
        }
      } else {
        debugPrint('API 호출 실패: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
=======
      return _processResponse(response);
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)
    } catch (e) {
      debugPrint('Vertex AI API 호출 실패: $e');
      rethrow;
    }
>>>>>>> cc1d0ed3 (충돌 상황 해결)
  }

<<<<<<< HEAD
<<<<<<< HEAD
  // 인스턴스 소멸 시 리소스 정리 개선
=======
  /// 스킬 기반 퀴즈 생성 - 최적화 버전
  Future<Map<String, dynamic>> generateQuiz(String skillArea) async {
    try {
      // 캐시 키 생성
      final cacheKey = _generateCacheKey('quiz', skillArea);
=======
  /// 응답 처리 메서드 (응답에서 JSON 추출)
  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
>>>>>>> 59b5ad53 (feat(AI): 성능개선을 위한 정리 1)

      try {
        // 응답 구조 확인 및 안전하게 처리
        final candidates = data['candidates'];
        if (candidates == null || candidates.isEmpty) {
          throw Exception('응답에 candidates가 없습니다');
        }
=======
  /// 텍스트 생성 API 호출 - JSON 배열 반환
  Future<List<Map<String, dynamic>>> callTextModelForList(String prompt) async {
    try {
      if (!_initialized) await initialize();

      // 다양성을 위한 랜덤 temperature 설정
      final random = Random();
      final temperature = 0.5 + random.nextDouble() * 0.4; // 0.5~0.9
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)

      // 고유 ID 추가
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final enhancedPrompt = '$prompt\n\n요청 ID: $uniqueId';

      debugPrint(
        'Gemini API 리스트 호출 시작: ${prompt.substring(0, min(50, prompt.length))}...',
      );

      // 동적으로 temperature 조정된 모델 생성
      final dynamicModel = _firebaseAI.generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: temperature,
          maxOutputTokens: 1024,
          topK: 40,
          topP: 0.95,
        ),
      );

      // Firebase AI SDK를 사용한 호출
      final response = await dynamicModel.generateContent([
        Content.text(enhancedPrompt),
      ]);

      // 응답 텍스트 추출
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('응답이 비어있습니다');
      }

      debugPrint(
        'Gemini API 리스트 응답 수신: ${responseText.substring(0, min(100, responseText.length))}...',
      );

      // JSON 배열 추출 및 반환
      return _extractJsonArrayFromText(responseText);
    } catch (e) {
      debugPrint('Gemini API 리스트 호출 실패: $e');
      rethrow;
    }
  }

  /// 텍스트에서 JSON 객체 추출
  Map<String, dynamic> _extractJsonFromText(String text) {
    // 코드 블록 제거
    String cleanedText = text;
    if (cleanedText.contains('```')) {
      cleanedText =
          cleanedText.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    // JSON 객체 찾기
    final jsonStart = cleanedText.indexOf('{');
    final jsonEnd = cleanedText.lastIndexOf('}') + 1;

    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      final jsonString = cleanedText.substring(jsonStart, jsonEnd);
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        debugPrint('JSON 객체 파싱 오류: $e');
        throw Exception('JSON 객체 파싱 오류: $e');
      }
    } else {
      debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $text');
      throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
    }
  }

  /// 텍스트에서 JSON 배열 추출
  List<Map<String, dynamic>> _extractJsonArrayFromText(String text) {
    // 코드 블록 제거
    String cleanedText = text;
    if (cleanedText.contains('```')) {
      cleanedText =
          cleanedText.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    // 먼저 배열 형태 확인
    final arrayStart = cleanedText.indexOf('[');
    final arrayEnd = cleanedText.lastIndexOf(']') + 1;

    if (arrayStart >= 0 && arrayEnd > arrayStart) {
      try {
        final List<dynamic> parsedArray = jsonDecode(
          cleanedText.substring(arrayStart, arrayEnd),
        );
        return parsedArray
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (e) {
        debugPrint('JSON 배열 파싱 오류: $e');
        // 배열 파싱 실패 시, 단일 객체 확인
        return [_extractJsonFromText(cleanedText)];
      }
    } else {
      // 배열을 찾을 수 없는 경우, 단일 객체 확인
      try {
        final singleObject = _extractJsonFromText(cleanedText);
        return [singleObject]; // 단일 객체를 리스트로 반환
      } catch (e) {
        debugPrint('JSON 형식을 찾을 수 없음: $text');
        throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
      }
    }
  }

<<<<<<< HEAD
  // 인스턴스 소멸 시 리소스 정리
>>>>>>> 96d3ead6 ([Optimize] AI Client Provider 성능 개선)
=======
  /// 리소스 정리
>>>>>>> b28e09d8 (fix(ai) vertex ai 에서 firebase ai로 변경)
  void dispose() {
    _initialized = false;
    _initializing = false;
    debugPrint('Firebase AI 클라이언트 리소스 정리 완료');
  }
}
