// lib/ai_assistance/module/vertex_client.dart 개선버전

import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/aiplatform/v1.dart' as vertex_ai;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VertexAIClient {
  // 싱글톤 패턴 유지
  static final VertexAIClient _instance = VertexAIClient._internal();

  factory VertexAIClient() => _instance;

  VertexAIClient._internal();

  // GCP 프로젝트 설정
  final String _projectId = 'gaesubang-2f372';
  final String _location = 'us-central1';
  final String _modelId = 'gemini-2.0-flash';

  // 초기화 상태 관리 개선
  bool _initialized = false;
  bool _initializing = false;
  Completer<void>? _initializeCompleter;

  // 클라이언트 인스턴스
  late http.Client _httpClient;
  late AutoRefreshingAuthClient _authClient;

  // 캐싱 매커니즘 추가 - 응답 캐시 (메모리 내)
  final Map<String, dynamic> _responseCache = {};

  // 캐시 유효 시간 (24시간)
  final Duration _cacheDuration = const Duration(hours: 24);

  // 캐시 타임스탬프 저장
  final Map<String, DateTime> _cacheTimestamps = {};

  /// 초기화 메서드 개선
  Future<void> initialize() async {
    // 이미 초기화 완료된 경우 즉시 반환
    if (_initialized) return;

    // 초기화가 진행 중인 경우 해당 작업이 완료될 때까지 대기
    if (_initializing) {
      debugPrint('Vertex AI 클라이언트 초기화 진행 중... 기존 작업 완료 대기');
      return _initializeCompleter!.future;
    }

    // 초기화 진행 중 플래그 설정 및 Completer 생성
    _initializing = true;
    _initializeCompleter = Completer<void>();

    try {
      debugPrint('Vertex AI 클라이언트 초기화 시작');

      // Remote Config에서 Base64로 인코딩된 서비스 계정 키 가져오기
      final Map<String, dynamic> serviceAccountJson =
      await _loadServiceAccountFromRemoteConfig();

      if (serviceAccountJson.isEmpty) {
        throw Exception('서비스 계정 정보를 Remote Config에서 로드할 수 없습니다.');
      }

      // 서비스 계정 정보 로드 및 인증 클라이언트 생성
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );

      _httpClient = http.Client();
      _authClient = await clientViaServiceAccount(credentials, [
        vertex_ai.AiplatformApi.cloudPlatformScope,
      ]);

      _initialized = true;
      _initializing = false;
      debugPrint('Vertex AI 클라이언트 초기화 완료');

      // 완료 알림
      _initializeCompleter!.complete();
    } catch (e) {
      debugPrint('Vertex AI 클라이언트 초기화 실패: $e');
      _initialized = false;
      _initializing = false;

      // 오류 전파
      _initializeCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Remote Config에서 Base64로 인코딩된 서비스 계정 키를 가져오는 메서드
  Future<Map<String, dynamic>> _loadServiceAccountFromRemoteConfig() async {
    try {
      // Remote Config 인스턴스 가져오기
      final remoteConfig = FirebaseRemoteConfig.instance;

      // 설정 로드
      await remoteConfig.fetchAndActivate();

      // Base64로 인코딩된 서비스 계정 JSON 가져오기
      final encodedServiceAccount = remoteConfig.getString('gaesubang_api_key');

      if (encodedServiceAccount.isEmpty) {
        debugPrint('Remote Config에서 서비스 계정 정보를 찾을 수 없습니다.');
        // 폴백: 로컬 파일에서 로드 시도
        return await _loadServiceAccountFromAssets();
      }

      // Base64 디코딩
      final Uint8List decodedBytes = base64Decode(encodedServiceAccount);
      final String decodedString = utf8.decode(decodedBytes);

      // JSON 파싱
      final Map<String, dynamic> serviceAccountJson = jsonDecode(decodedString);

      debugPrint('Remote Config에서 서비스 계정 정보 로드 완료');
      return serviceAccountJson;
    } catch (e) {
      debugPrint('Remote Config에서 서비스 계정 정보 로드 실패: $e');
      // 폴백: 로컬 파일에서 로드 시도
      return await _loadServiceAccountFromAssets();
    }
  }

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
  Future<Map<String, dynamic>> callTextModel(String prompt) async {
    try {
      // 캐시 키 생성
      final cacheKey = _generateCacheKey('text', prompt);

      // 캐시 확인
      if (_isCacheValid(cacheKey)) {
        debugPrint('✅ 캐시에서 응답 로드: $cacheKey');
        return Map<String, dynamic>.from(_responseCache[cacheKey]);
      }

      // 초기화 확인
      if (!_initialized) await initialize();

      // 기존 엔드포인트 로직
      final endpoint = 'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';

      // 페이로드 구성 - 파라미터 최적화
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
          'maxOutputTokens': 800, // 토큰 수 적절히 감소
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

      // 응답 처리
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

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
    } catch (e) {
      debugPrint('Vertex AI API 호출 실패: $e');

      // 폴백 응답 - 다양한 주제별 폴백 제공
      final defaultResponse = _getDefaultStudyTip(prompt);

      // 폴백 응답도 캐시에 저장 (재시도 방지)
      final cacheKey = _generateCacheKey('text', prompt);
      _cacheResponse(cacheKey, defaultResponse);

      return defaultResponse;
    }
  }

  /// 스킬 기반 퀴즈 생성 - 최적화 버전
  Future<Map<String, dynamic>> generateQuiz(String skillArea) async {
    try {
      // 캐시 키 생성
      final cacheKey = _generateCacheKey('quiz', skillArea);

      // 캐시 확인
      if (_isCacheValid(cacheKey)) {
        debugPrint('✅ 캐시에서 퀴즈 로드: $cacheKey');
        return Map<String, dynamic>.from(_responseCache[cacheKey]);
      }

      // 초기화 확인
      if (!_initialized) await initialize();

      // 스킬 확인 및 기본값 설정
      final skill = skillArea.isNotEmpty ? skillArea : '컴퓨터 기초';

      // 단일 퀴즈 생성을 위한 프롬프트 구성 - 간결화
      final prompt = """
      프로그래밍 퀴즈 생성: $skill 영역의 객관식 문제 1개
      JSON 형식: {"question":"문제","options":["보기1","보기2","보기3","보기4"],"correctOptionIndex":0,"explanation":"설명","relatedSkill":"$skill"}
      난이도: 초급~중급
      """;

      // API 호출
      final endpoint = 'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';

      // 페이로드 구성 - 최적화
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
          'maxOutputTokens': 800,
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

      // 응답 처리
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String generatedText = data['candidates'][0]['content']['parts'][0]['text'] ?? '';

        // JSON 추출 (정규식 사용으로 개선)
        final RegExp jsonRegex = RegExp(r'{[\s\S]*}');
        final match = jsonRegex.firstMatch(generatedText);

        if (match != null) {
          final jsonString = match.group(0)!;
          final Map<String, dynamic> result = jsonDecode(jsonString);

          // 필수 필드 확인
          if (!result.containsKey('question') || !result.containsKey('options')) {
            throw Exception('응답에 필수 필드가 없습니다');
          }

          // 캐시에 저장
          _cacheResponse(cacheKey, result);

          return result;
        } else {
          throw Exception('JSON 형식을 찾을 수 없습니다');
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('퀴즈 생성 실패: $e');

      // 폴백 퀴즈 생성
      final fallbackQuiz = _generateFallbackQuiz(skillArea);

      // 폴백 응답도 캐시
      final cacheKey = _generateCacheKey('quiz', skillArea);
      _cacheResponse(cacheKey, fallbackQuiz);

      return fallbackQuiz;
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
  }

  /// 기본 학습 팁 생성 메서드 (폴백용) - 새로 추가
  Map<String, dynamic> _getDefaultStudyTip(String prompt) {
    // 주제별 다양한 폴백 제공
    if (prompt.toLowerCase().contains('python')) {
      return {
        "title": "파이썬 학습 시 실습 중심으로 접근하기",
        "content": "파이썬을 효과적으로 배우려면 단순히 읽는 것보다 직접 코드를 작성해보는 것이 중요합니다. 작은 프로젝트를 만들거나 코딩 챌린지를 통해 학습하는 것이 효과적입니다. 또한 파이썬의 공식 문서와 함께 Stack Overflow를 적극 활용하세요.",
        "relatedSkill": "Python",
        "englishPhrase": "Readability counts.",
        "translation": "가독성이 중요하다.",
        "source": "The Zen of Python"
      };
    } else if (prompt.toLowerCase().contains('flutter') ||
        prompt.toLowerCase().contains('dart')) {
      return {
        "title": "Flutter 개발자를 위한 위젯 이해하기",
        "content": "Flutter에서 모든 것은 위젯입니다. StatefulWidget과 StatelessWidget의 차이를 확실히 이해하고 각각 언제 사용해야 하는지 파악하는 것이 중요합니다. Flutter 개발자 도구를 활용해 위젯 트리를 분석하고 성능 이슈를 디버깅하세요.",
        "relatedSkill": "Flutter",
        "englishPhrase": "Everything is a widget.",
        "translation": "모든 것이 위젯이다.",
        "source": "Flutter 공식 문서"
      };
    } else if (prompt.toLowerCase().contains('javascript') ||
        prompt.toLowerCase().contains('js')) {
      return {
        "title": "JavaScript 비동기 처리 마스터하기",
        "content": "JavaScript에서 Promise와 async/await을 확실히 이해하는 것이 중요합니다. 비동기 코드를 동기 코드처럼 작성할 수 있게 해주는 async/await을 활용하면 코드 가독성이 크게 향상됩니다. 단, 항상 에러 처리를 위한 try-catch 구문을 함께 사용하세요.",
        "relatedSkill": "JavaScript",
        "englishPhrase": "Callback hell is real, but avoidable.",
        "translation": "콜백 지옥은 실존하지만, 피할 수 있다.",
        "source": "JavaScript 커뮤니티"
      };
    }

    // 기본 팁 (프로그래밍 일반)
    return {
      "title": "개발자를 위한 시간 관리 팁",
      "content": "효과적인 개발을 위해서는 '딥 워크'가 필요합니다. 2-3시간 동안 방해 없이 집중할 수 있는 환경을 만드세요. 알림을 끄고, 동료들에게 집중 시간임을 알리고, 소음 차단 헤드폰을 활용하세요. 포모도로 기법(25분 집중 + 5분 휴식)도 효과적입니다.",
      "relatedSkill": "프로그래밍 기초",
      "englishPhrase": "Premature optimization is the root of all evil.",
      "translation": "때 이른 최적화는 모든 악의 근원이다.",
      "source": "Donald Knuth"
    };
  }

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _httpClient.close();
      _authClient.close();
      _initialized = false;
      _initializing = false;
      _initializeCompleter = null;

      // 캐시 정리
      _responseCache.clear();
      _cacheTimestamps.clear();
    }
  }
}