import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

abstract interface class VertexAiDataSource {
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt);
}

class VertexAiDataSourceImpl implements VertexAiDataSource {
  final FirebaseRemoteConfig _remoteConfig;
  final http.Client _httpClient;

  VertexAiDataSourceImpl({
    required FirebaseRemoteConfig remoteConfig,
    http.Client? httpClient,
  }) : _remoteConfig = remoteConfig,
       _httpClient = httpClient ?? http.Client();

  @override
  Future<Map<String, dynamic>> generateQuizWithPrompt(String prompt) async {
    try {
      // 1. Remote Config에서 Vertex AI 키 정보 가져오기
      final vertexAiKeyJson = _remoteConfig.getString('vertex_ai_key');
      if (vertexAiKeyJson.isEmpty) {
        throw Exception('Vertex AI 키를 찾을 수 없습니다');
      }

      final keyConfig = json.decode(vertexAiKeyJson) as Map<String, dynamic>;
      final projectId = keyConfig['project_id'] as String?;
      final location = keyConfig['location'] as String? ?? 'us-central1';
      final apiKey = keyConfig['api_key'] as String?;

      if (projectId == null || apiKey == null) {
        throw Exception('Vertex AI 설정이 올바르지 않습니다');
      }

      // 2. Vertex AI API 호출 URL 구성
      final url = Uri.parse(
        'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/publishers/google/models/gemini-2.0-flash:generateContent',
      );

      // 3. API 요청 본문 구성
      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topP': 0.8,
          'topK': 40,
          'maxOutputTokens': 1024,
        },
      };

      // 4. API 호출
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: json.encode(requestBody),
      );

      // 5. 응답 처리
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final candidates = jsonResponse['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) {
              // JSON 형태로 반환된 텍스트 파싱
              try {
                return json.decode(text) as Map<String, dynamic>;
              } catch (e) {
                // JSON 파싱이 실패한 경우 텍스트를 question 필드에 넣어 반환
                return {
                  'question': text,
                  'options': [],
                  'answer': '',
                  'explanation': '',
                };
              }
            }
          }
        }
      }

      // 오류 응답 로깅
      print('Vertex AI API 오류: ${response.statusCode} - ${response.body}');
      throw Exception('퀴즈 생성에 실패했습니다 (${response.statusCode})');
    } catch (e) {
      print('Vertex AI 호출 중 예외 발생: $e');
      throw Exception('퀴즈 생성 중 오류가 발생했습니다: $e');
    }
  }
}
