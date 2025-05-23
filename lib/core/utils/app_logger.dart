// lib/core/utils/app_logger.dart
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

/// VSCode 환경에 최적화된 앱 로거
class AppLogger {
  static bool _isVSCodeEnvironment = true; // VSCode 환경 기본값
  static bool _enableColors = false; // VSCode에서는 컬러 비활성화

  // 로그 레벨 정의
  static const int _levelDebug = 500;
  static const int _levelInfo = 800;
  static const int _levelWarning = 900;
  static const int _levelError = 1000;
  static const int _levelSevere = 1200;

  /// VSCode 환경 감지 및 설정
  static void initialize() {
    // VSCode 환경에서는 ANSI 컬러 코드 비활성화
    _isVSCodeEnvironment =
        Platform.environment.containsKey('VSCODE_PID') ||
        Platform.environment.containsKey('TERM_PROGRAM');
    _enableColors = !_isVSCodeEnvironment && !kIsWeb;
  }

  // ==========================================================================
  // 기본 로그 메서드들
  // ==========================================================================

  /// 디버그 로그
  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message: message,
      level: _levelDebug,
      tag: tag ?? 'Debug',
      icon: '🔍',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 정보 로그
  static void info(String message, {String? tag}) {
    _log(
      message: message,
      level: _levelInfo,
      tag: tag ?? 'Info',
      icon: '💡',
    );
  }

  /// 경고 로그
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message: message,
      level: _levelWarning,
      tag: tag ?? 'Warning',
      icon: '⚠️',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 에러 로그
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message: message,
      level: _levelError,
      tag: tag ?? 'Error',
      icon: '❌',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 심각한 에러 로그
  static void severe(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message: message,
      level: _levelSevere,
      tag: tag ?? 'Severe',
      icon: '🔥',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ==========================================================================
  // 도메인별 로그 메서드들
  // ==========================================================================

  /// 커뮤니티 관련 정보 로그
  static void communityInfo(String message) {
    info(message, tag: 'Community');
  }

  /// 커뮤니티 관련 에러 로그
  static void communityError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      message,
      tag: 'Community',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 네트워크 관련 에러 로그
  static void networkError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.error(
      message,
      tag: 'Network',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 인증 관련 정보 로그
  static void authInfo(String message) {
    info(message, tag: 'Auth');
  }

  /// UI 관련 정보 로그
  static void ui(String message) {
    info(message, tag: 'UI');
  }

  /// 네비게이션 관련 정보 로그
  static void navigation(String message) {
    info(message, tag: 'Navigation');
  }

  // ==========================================================================
  // 특수 포맷 로그 메서드들
  // ==========================================================================

  /// 박스 형태의 로그 (VSCode 친화적)
  static void logBox(String title, String content) {
    final divider = '─' * 50;
    final lines = [
      '┌$divider┐',
      '│ 📦 $title',
      '├$divider┤',
      '│ $content',
      '└$divider┘',
    ];

    for (final line in lines) {
      developer.log(line, name: 'App', level: _levelInfo);
    }
  }

  /// 단계별 로그
  static void logStep(int current, int total, String message) {
    final progress = '[$current/$total]';
    developer.log(
      '🔄 $progress $message',
      name: 'App',
      level: _levelInfo,
    );
  }

  /// 배너 형태의 로그
  static void logBanner(String message) {
    final stars = '★' * 3;
    developer.log(
      '$stars $message $stars',
      name: 'App',
      level: _levelInfo,
    );
  }

  /// 검색 관련 로그
  static void searchInfo(String query, int resultCount) {
    logBox('검색 결과', '검색어: "$query" - $resultCount개 결과');
  }

  // ==========================================================================
  // 내부 메서드들
  // ==========================================================================

  /// 통합 로그 메서드
  static void _log({
    required String message,
    required int level,
    required String tag,
    required String icon,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 기본 메시지 포맷팅
    final formattedMessage = _formatMessage(message, icon);

    // 메인 로그 출력
    developer.log(
      formattedMessage,
      name: tag,
      level: level,
      time: DateTime.now(),
    );

    // 에러 정보가 있으면 추가 출력
    if (error != null) {
      developer.log(
        '┗━ ❌ Error: $error',
        name: tag,
        level: level,
      );
    }

    // 스택트레이스가 있으면 추가 출력
    if (stackTrace != null) {
      developer.log(
        '┗━ 📍 Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}',
        name: tag,
        level: level,
      );
    }
  }

  /// 메시지 포맷팅
  static String _formatMessage(String message, String icon) {
    final timestamp = _formatTimestamp(DateTime.now());
    return '$icon $timestamp $message';
  }

  /// 타임스탬프 포맷팅
  static String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}.'
        '${dateTime.millisecond.toString().padLeft(3, '0')}';
  }

  // ==========================================================================
  // 유틸리티 메서드들
  // ==========================================================================

  /// 조건부 로그 출력
  static void logIf(bool condition, String message, {String? tag}) {
    if (condition) {
      info(message, tag: tag);
    }
  }

  /// 객체 상태 로그
  static void logState(String objectName, Map<String, dynamic> state) {
    final stateString = state.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    debug('$objectName 상태: {$stateString}');
  }

  /// 성능 측정 로그
  static void logPerformance(String operation, Duration duration) {
    final milliseconds = duration.inMilliseconds;
    final icon = milliseconds > 1000 ? '🐌' : '⚡';

    info('$icon $operation 완료: ${milliseconds}ms', tag: 'Performance');
  }
}
