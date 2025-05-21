import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
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
  final String _modelId = 'gemini-2.0-flash'; // 또는 사용하려는 모델 ID로 변경

  // 초기화 상태
  bool _initialized = false;
  late http.Client _httpClient;
  String? _apiKey;

  /// 초기화 메서드
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _httpClient = http.Client();

      // Remote Config에서 API 키 가져오기 시도
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetchAndActivate();
        _apiKey = remoteConfig.getString('gaesubang_ai_key');

        if (_apiKey == null || _apiKey!.isEmpty) {
          debugPrint('Firebase Remote Config에서 API 키를 찾지 못했습니다.');
        } else {
          debugPrint('Vertex AI API 키를 성공적으로 로드했습니다.');
        }
      } catch (e) {
        debugPrint('Remote Config에서 API 키 로드 실패: $e');
      }

      _initialized = true;
      debugPrint('Vertex AI 클라이언트 초기화 완료');
    } catch (e) {
      debugPrint('Vertex AI 클라이언트 초기화 실패: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Firebase 프로젝트 설정의 API 키 가져오기
  String? _getApiKey() {
    // 1. Remote Config에서 로드한 키 사용
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      return _apiKey;
    }

    // 2. Firebase 옵션에서 API 키 가져오기
    try {
      return FirebaseAuth.instance.app.options.apiKey;
    } catch (e) {
      debugPrint('Firebase 옵션에서 API 키 가져오기 실패: $e');
      return null;
    }
  }

  /// 퀴즈 생성 메서드
  Future<Map<String, dynamic>> generateQuiz(String skillArea) async {
    try {
      if (!_initialized) await initialize();

      // API 키 확인
      final apiKey = _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('유효한 API 키를 찾을 수 없습니다');
      }

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
        "answer": "정답(보기 중 하나와 정확히 일치해야 함)",
        "explanation": "간략한 설명",
        "skillArea": "$skillArea"
      }

      직접적인 설명 없이 JSON 형식으로만 응답해주세요.
      """;

      try {
        // Vertex AI API 엔드포인트
        final endpoint =
            'https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/$_modelId:predict';

        // API 요청 본문 구성
        final payload = {
          'instances': [
            {'prompt': prompt},
          ],
          'parameters': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
            'topK': 40,
            'topP': 0.95,
          },
        };

        // API 키를 헤더에 포함
        final uri = Uri.parse(endpoint);

        debugPrint('Vertex AI API 요청 시작...');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
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

        // Vertex AI 응답 구조 파싱
        final predictions = data['predictions'] as List<dynamic>?;
        if (predictions == null || predictions.isEmpty) {
          throw Exception('응답에 predictions가 없습니다');
        }

        final content = predictions[0]['content'] as String? ?? '';

        // JSON 파싱 (생성된 텍스트에서 JSON 부분 추출)
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = content.substring(jsonStart, jsonEnd);

          try {
            final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
            return parsedJson;
          } catch (e) {
            debugPrint('JSON 파싱 오류: $e');
            throw Exception('JSON 파싱 오류: $e');
          }
        } else {
          // 전체 텍스트 출력
          debugPrint('JSON 형식을 찾을 수 없음. 전체 텍스트: $content');
          throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
        }
      } catch (e) {
        debugPrint('API 호출 오류: $e');
        throw e;
      }
    } catch (e) {
      debugPrint('Vertex AI 호출 중 예외 발생: $e');
      return _generateFallbackQuiz(skillArea);
    }
  }

  /// 폴백 퀴즈 데이터 생성 메서드
  Map<String, dynamic> _generateFallbackQuiz(String prompt) {
    // 기존 폴백 퀴즈 코드 유지
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
        "answer": "코드가 더 간결하고 가독성이 좋아짐",
        "explanation":
            "리스트 컴프리헨션은 반복문과 조건문을 한 줄로 작성할 수 있어 코드가 더 간결해지고 가독성이 향상됩니다.",
        "skillArea": "Python",
      };
    }

    // 다른 폴백 퀴즈 케이스들...

    // 기본 컴퓨터 기초 퀴즈
    return {
      "question": "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
      "options": ["4비트", "8비트", "16비트", "32비트"],
      "answer": "8비트",
      "explanation": "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
      "skillArea": "컴퓨터 기초",
    };
  }

  // 인스턴스 소멸 시 리소스 정리
  void dispose() {
    if (_initialized) {
      _httpClient.close();
      _initialized = false;
    }
  }
}
