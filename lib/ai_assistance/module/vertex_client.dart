import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/aiplatform/v1.dart' as vertex_ai;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Vertex AI와의 통신을 담당하는 클라이언트 클래스
/// API 호출과 응답 처리에만 집중하도록 리팩토링
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
  bool _initializing = false;
  Completer<void>? _initializeCompleter;

  late http.Client _httpClient;
  late AutoRefreshingAuthClient _authClient;

  /// 초기화 메서드
  Future<void> initialize() async {
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

  /// 텍스트 생성 API 호출 메서드 - 프롬프트를 받아 JSON 응답 반환
  /// 이 메서드는 프롬프트 내용에 관여하지 않고 API 호출과 응답 처리에만 집중
  Future<Map<String, dynamic>> callTextModel(String prompt) async {
    try {
      if (!_initialized) await initialize();

      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';

      // 캐시 방지를 위한 고유 ID 추가
      final uniqueId = DateTime.now().millisecondsSinceEpoch;

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
          'maxOutputTokens': 1024,
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

      // 응답 처리
      return _processResponse(response);
    } catch (e) {
      debugPrint('Vertex AI API 호출 실패: $e');
      rethrow;
    }
  }

  /// 응답 처리 메서드 (응답에서 JSON 추출)
  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 200) {
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

      final endpoint =
          'https://aiplatform.googleapis.com/v1/projects/${_projectId}/locations/${_location}/publishers/google/models/${_modelId}:generateContent';

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
          'topK': 40,
          'topP': 0.95,
        },
      };

      // API 호출
      final response = await _authClient.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: jsonEncode(payload),
      );

      // 응답 처리
      return _processListResponse(response);
    } catch (e) {
      debugPrint('Vertex AI API 리스트 호출 실패: $e');
      rethrow;
    }
  }

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
        try {
          final Map<String, dynamic> parsedJson = jsonDecode(
            text.substring(jsonStart, jsonEnd),
          );
          return [parsedJson]; // 단일 객체를 리스트로 반환
        } catch (e) {
          debugPrint('JSON 객체 파싱 오류: $e');
          throw Exception('JSON 객체 파싱 오류: $e');
        }
      } else {
        debugPrint('JSON 형식을 찾을 수 없음: $text');
        throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
      }
    }
  }

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _httpClient.close();
      _authClient.close();
      _initialized = false;
      _initializing = false;
      _initializeCompleter = null;
    }
  }
}
