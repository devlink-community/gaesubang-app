// lib/core/utils/app_logger.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppLogger {
  static bool _initialized = false;

  /// 로거 초기화 (앱 시작 시 한 번만 호출)
  static void initialize() {
    if (_initialized) return;

    // 계층적 로깅 활성화
    hierarchicalLoggingEnabled = true;
    
    // 루트 로거 설정
    Logger.root.level = _getRootLevel();
    Logger.root.onRecord.listen(_handleLogRecord);
    
    _initialized = true;
  }

  /// 환경별 로그 레벨 결정
  static Level _getRootLevel() {
    if (kReleaseMode) {
      return Level.WARNING; // 릴리즈에서는 경고 이상만
    } else {
      return Level.INFO; // 개발 모드에서는 INFO 이상
    }
  }

  /// 로그 레코드 처리
  static void _handleLogRecord(LogRecord record) {
    // 개발 모드에서만 콘솔 출력
    if (kDebugMode) {
      final message = _formatLogMessage(record);
      print(message);
    }

    // 에러는 항상 dart:developer log로도 기록
    if (record.level >= Level.SEVERE) {
      developer.log(
        record.message,
        name: record.loggerName,
        time: record.time,
        level: _convertLevel(record.level),
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }
  }

  /// 로그 메시지 포맷팅 (logger 패키지 스타일)
  static String _formatLogMessage(LogRecord record) {
    final emoji = _getEmojiForLevel(record.level);
    final colorCode = _getColorForLevel(record.level);
    final resetColor = '\x1B[0m';
    final time = record.time.toString().substring(11, 23); // HH:mm:ss.SSS
    final logger = record.loggerName.isNotEmpty ? '[${record.loggerName}]' : '';
    final levelName = record.level.name.padRight(7);
    
    // 메인 로그 라인
    var message = '$colorCode$emoji $time $levelName$logger$resetColor ${record.message}';
    
    // 에러 정보 추가
    if (record.error != null) {
      message += '\n$colorCode┗━ ❌ Error: ${record.error}$resetColor';
    }
    
    // 스택트레이스 추가 (간략하게)
    if (record.stackTrace != null && kDebugMode) {
      final stackLines = record.stackTrace.toString().split('\n');
      final relevantLines = stackLines
          .where((line) => line.contains('package:devlink_mobile_app'))
          .take(3)
          .join('\n   ');
      
      if (relevantLines.isNotEmpty) {
        message += '\n$colorCode┗━ 📍 Stack:$resetColor\n   $relevantLines';
      }
    }
    
    return message;
  }

  /// 로그 레벨별 이모지 반환
  static String _getEmojiForLevel(Level level) {
    if (level >= Level.SEVERE) return '🔥'; // SEVERE/ERROR
    if (level >= Level.WARNING) return '⚠️'; // WARNING
    if (level >= Level.INFO) return '💡'; // INFO
    if (level >= Level.CONFIG) return '⚙️'; // CONFIG
    if (level >= Level.FINE) return '🐛'; // DEBUG/FINE
    return '📝'; // FINER/FINEST
  }

  /// 로그 레벨별 색상 코드 반환 (ANSI)
  static String _getColorForLevel(Level level) {
    if (level >= Level.SEVERE) return '\x1B[91m'; // 밝은 빨강
    if (level >= Level.WARNING) return '\x1B[93m'; // 밝은 노랑
    if (level >= Level.INFO) return '\x1B[96m'; // 밝은 청록
    if (level >= Level.CONFIG) return '\x1B[95m'; // 밝은 자홍
    if (level >= Level.FINE) return '\x1B[92m'; // 밝은 초록
    return '\x1B[37m'; // 밝은 회색
  }

  /// Level을 dart:developer의 레벨로 변환
  static int _convertLevel(Level level) {
    if (level >= Level.SEVERE) return 1000;
    if (level >= Level.WARNING) return 900;
    if (level >= Level.INFO) return 800;
    return 700;
  }

  // 로거 팩토리 메서드
  static Logger _getLogger(String name) {
    if (!_initialized) initialize();
    return Logger(name);
  }

  // 카테고리별 로거들
  static final Logger _ui = _getLogger('UI');
  static final Logger _navigation = _getLogger('Navigation');
  static final Logger _business = _getLogger('Business');
  static final Logger _network = _getLogger('Network');
  static final Logger _auth = _getLogger('Auth');
  static final Logger _community = _getLogger('Community');
  static final Logger _general = _getLogger('App');

  // 일반 로깅 메서드들
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logger = tag != null ? _getLogger(tag) : _general;
    logger.fine(message, error, stackTrace);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logger = tag != null ? _getLogger(tag) : _general;
    logger.info(message, error, stackTrace);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logger = tag != null ? _getLogger(tag) : _general;
    logger.warning(message, error, stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logger = tag != null ? _getLogger(tag) : _general;
    logger.severe(message, error, stackTrace);
  }

  // 카테고리별 편의 메서드들
  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    _ui.fine(message, error, stackTrace);
  }

  static void navigation(String message, {Object? error, StackTrace? stackTrace}) {
    _navigation.info(message, error, stackTrace);
  }

  static void business(String message, {Object? error, StackTrace? stackTrace}) {
    _business.info(message, error, stackTrace);
  }

  static void networkInfo(String message, {Object? error, StackTrace? stackTrace}) {
    _network.info(message, error, stackTrace);
  }

  static void networkError(String message, {Object? error, StackTrace? stackTrace}) {
    _network.severe(message, error, stackTrace);
  }

  static void authInfo(String message, {Object? error, StackTrace? stackTrace}) {
    _auth.info(message, error, stackTrace);
  }

  static void authError(String message, {Object? error, StackTrace? stackTrace}) {
    _auth.severe(message, error, stackTrace);
  }

  static void communityInfo(String message, {Object? error, StackTrace? stackTrace}) {
    _community.info(message, error, stackTrace);
  }

  static void communityError(String message, {Object? error, StackTrace? stackTrace}) {
    _community.severe(message, error, stackTrace);
  }

  /// 특정 로거의 레벨 동적 변경
  static void setLoggerLevel(String name, Level level) {
    _getLogger(name).level = level;
  }

  /// 디버그 모드에서 모든 로그 활성화
  static void enableVerbose() {
    Logger.root.level = Level.ALL;
  }

  /// 모든 로깅 비활성화 (긴급 상황용)
  static void disableAll() {
    Logger.root.level = Level.OFF;
  }

  /// 로깅 재활성화
  static void enableAll() {
    Logger.root.level = _getRootLevel();
  }

  // 🎨 예쁜 로깅 메서드들 (특별한 경우에 사용)
  
  /// 박스 스타일 로그 (중요한 시작/완료 시)
  static void logBox(String title, String message, {Level level = Level.INFO}) {
    final logger = _getLogger('Box');
    final colorCode = _getColorForLevel(level);
    final resetColor = '\x1B[0m';
    
    final boxMessage = '''
$colorCode╭─────────────────────────────────────────╮
│ 📦 $title
├─────────────────────────────────────────┤
│ $message
╰─────────────────────────────────────────╯$resetColor''';
    
    logger.log(level, boxMessage);
  }

  /// 배너 스타일 로그 (앱 시작 등)
  static void logBanner(String message) {
    final logger = _getLogger('Banner');
    final bannerMessage = '''
🚀═══════════════════════════════════════════════════════════════
   $message
═══════════════════════════════════════════════════════════════''';
    
    logger.info(bannerMessage);
  }

  /// 단계별 진행 로그
  static void logStep(int step, int total, String message) {
    final progress = '[$step/$total]';
    final progressBar = '█' * ((step * 10) ~/ total) + '░' * (10 - (step * 10) ~/ total);
    
    info('$progress $progressBar $message', tag: 'Progress');
  }
}