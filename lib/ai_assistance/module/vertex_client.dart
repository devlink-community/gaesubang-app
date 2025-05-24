import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Firebase AI를 사용한 Gemini API 클라이언트
/// 기존 Vertex AI 클라이언트를 대체하여 더 간단하고 효율적인 구조 제공
class FirebaseAIClient {
  // 싱글톤 패턴
  static final FirebaseAIClient _instance = FirebaseAIClient._internal();

  factory FirebaseAIClient() => _instance;

  FirebaseAIClient._internal();

  // 🔧 개선된 초기화 상태 관리
  bool _initialized = false;

  // 🆕 Completer 기반 초기화 - 경합 조건 해결
  Completer<void>? _initCompleter;

  late GenerativeModel _generativeModel;
  late FirebaseAI _firebaseAI;

  /// 🔧 개선된 초기화 메서드 - 경합 조건 및 무한 대기 방지
  Future<void> initialize() async {
    // 이미 초기화된 경우 즉시 반환
    if (_initialized) return;

    // 초기화가 진행 중인 경우 해당 Completer를 기다림
    if (_initCompleter != null) {
      AppLogger.debug(
        'Firebase AI 초기화가 이미 진행 중입니다. 완료를 기다립니다.',
        tag: 'FirebaseAI',
      );

      // 🔧 타임아웃 추가 - 무한 대기 방지
      try {
        await _initCompleter!.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            AppLogger.error(
              'Firebase AI 초기화 타임아웃 (30초)',
              tag: 'FirebaseAI',
            );
            throw TimeoutException('Firebase AI 초기화 타임아웃', const Duration(seconds: 30));
          },
        );
        return;
      } catch (e) {
        AppLogger.error(
          'Firebase AI 초기화 대기 중 오류 발생',
          tag: 'FirebaseAI',
          error: e,
        );

        // 실패한 Completer 정리
        _initCompleter = null;
        rethrow;
      }
    }

    // 새로운 초기화 시작
    _initCompleter = Completer<void>();

    try {
      AppLogger.info('Firebase AI 클라이언트 초기화 시작', tag: 'FirebaseAI');

      // Firebase Auth 확인 (필요 시 익명 로그인)
      if (FirebaseAuth.instance.currentUser == null) {
        AppLogger.debug('Firebase 익명 로그인 시작', tag: 'FirebaseAI');
        await FirebaseAuth.instance.signInAnonymously();
        AppLogger.info('Firebase 익명 로그인 완료', tag: 'FirebaseAI');
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

      // 🔧 성공 시 Completer 완료
      _initCompleter!.complete();
      _initCompleter = null;

      AppLogger.info('Firebase AI 클라이언트 초기화 완료', tag: 'FirebaseAI');
    } catch (e) {
      AppLogger.error(
        'Firebase AI 클라이언트 초기화 실패',
        tag: 'FirebaseAI',
        error: e,
      );

      // 🔧 실패 시 상태 정리 및 Completer 에러 완료
      _initialized = false;
      _initCompleter!.completeError(e);
      _initCompleter = null;

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

      AppLogger.info('Remote Config에서 Gemini API 키 로드 완료', tag: 'FirebaseAI');
      return apiKey;
    } catch (e) {
      AppLogger.error(
        'Remote Config에서 Gemini API 키 로드 실패',
        tag: 'FirebaseAI',
        error: e,
      );
      rethrow;
    }
  }

  Future<String> callTextModelForChat(String prompt) async {
    try {
      // 🔧 개선된 초기화 확인
      if (!_initialized) {
        AppLogger.debug('Firebase AI 미초기화 상태, 초기화 시도', tag: 'GeminiChat');
        await initialize();
      }

      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final enhancedPrompt = '$prompt\n\n요청 ID: $uniqueId';

      AppLogger.info(
        'Gemini 챗봇 API 호출: ${prompt.substring(0, min(50, prompt.length))}...',
        tag: 'GeminiChat',
      );

      final response = await _generativeModel.generateContent([
        Content.text(enhancedPrompt),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('응답이 비어있습니다');
      }

      AppLogger.info(
        'Gemini 챗봇 응답: ${responseText.substring(0, min(100, responseText.length))}...',
        tag: 'GeminiChat',
      );

      return responseText.trim();
    } catch (e) {
      AppLogger.error(
        'Gemini 챗봇 API 호출 실패',
        tag: 'GeminiChat',
        error: e,
      );
      rethrow;
    }
  }

  /// 텍스트 생성 API 호출 - 단일 JSON 객체 반환
  Future<Map<String, dynamic>> callTextModel(String prompt) async {
    try {
      // 🔧 개선된 초기화 확인
      if (!_initialized) {
        AppLogger.debug('Firebase AI 미초기화 상태, 초기화 시도', tag: 'GeminiAPI');
        await initialize();
      }

      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final enhancedPrompt = '$prompt\n\n요청 ID: $uniqueId';

      AppLogger.info(
        'Gemini API 호출 시작: ${prompt.substring(0, min(50, prompt.length))}...',
        tag: 'GeminiAPI',
      );

      final response = await _generativeModel.generateContent([
        Content.text(enhancedPrompt),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('응답이 비어있습니다');
      }

      AppLogger.info(
        'Gemini API 응답 수신: ${responseText.substring(0, min(100, responseText.length))}...',
        tag: 'GeminiAPI',
      );

      // JSON 추출 및 반환
      return _extractJsonFromText(responseText);
    } catch (e) {
      AppLogger.error(
        'Gemini API 호출 실패',
        tag: 'GeminiAPI',
        error: e,
      );
      rethrow;
    }
  }

  /// 텍스트 생성 API 호출 - JSON 배열 반환
  Future<List<Map<String, dynamic>>> callTextModelForList(String prompt) async {
    try {
      // 🔧 개선된 초기화 확인
      if (!_initialized) {
        AppLogger.debug('Firebase AI 미초기화 상태, 초기화 시도', tag: 'GeminiAPI');
        await initialize();
      }

      // 다양성을 위한 랜덤 temperature 설정
      final random = Random();
      final temperature = 0.5 + random.nextDouble() * 0.4; // 0.5~0.9

      // 고유 ID 추가
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final enhancedPrompt = '$prompt\n\n요청 ID: $uniqueId';

      AppLogger.info(
        'Gemini API 리스트 호출 시작: ${prompt.substring(0, min(50, prompt.length))}...',
        tag: 'GeminiAPI',
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

      AppLogger.info(
        'Gemini API 리스트 응답 수신: ${responseText.substring(0, min(100, responseText.length))}...',
        tag: 'GeminiAPI',
      );

      // JSON 배열 추출 및 반환
      return _extractJsonArrayFromText(responseText);
    } catch (e) {
      AppLogger.error(
        'Gemini API 리스트 호출 실패',
        tag: 'GeminiAPI',
        error: e,
      );
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
        AppLogger.error('JSON 객체 파싱 오류', tag: 'GeminiAPI', error: e);
        throw Exception('JSON 객체 파싱 오류: $e');
      }
    } else {
      AppLogger.error(
        'JSON 형식을 찾을 수 없음',
        tag: 'GeminiAPI',
        error: 'Response: $text',
      );
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
        AppLogger.error('JSON 배열 파싱 오류', tag: 'GeminiAPI', error: e);
        // 배열 파싱 실패 시, 단일 객체 확인
        return [_extractJsonFromText(cleanedText)];
      }
    } else {
      // 배열을 찾을 수 없는 경우, 단일 객체 확인
      try {
        final singleObject = _extractJsonFromText(cleanedText);
        return [singleObject]; // 단일 객체를 리스트로 반환
      } catch (e) {
        AppLogger.error(
          'JSON 형식을 찾을 수 없음',
          tag: 'GeminiAPI',
          error: 'Response: $text',
        );
        throw Exception('응답에서 JSON 형식을 찾을 수 없습니다');
      }
    }
  }

  /// 🆕 초기화 상태 확인 메서드
  bool get isInitialized => _initialized;

  /// 🆕 초기화 진행 상태 확인 메서드
  bool get isInitializing => _initCompleter != null;

  /// 🔧 개선된 리소스 정리
  void dispose() {
    _initialized = false;

    // 진행 중인 초기화가 있다면 취소
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(
        StateError('Firebase AI 클라이언트가 dispose되었습니다'),
      );
    }
    _initCompleter = null;

    AppLogger.info('Firebase AI 클라이언트 리소스 정리 완료', tag: 'FirebaseAI');
  }

  /// 🆕 초기화 상태 리셋 메서드 (테스트 및 디버깅용)
  void resetForTesting() {
    _initialized = false;
    _initCompleter = null;
    AppLogger.debug('Firebase AI 클라이언트 상태 리셋 완료', tag: 'FirebaseAI');
  }
}