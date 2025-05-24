// lib/core/utils/api_call_logger.dart
import 'package:devlink_mobile_app/core/utils/app_logger.dart';

import '../config/app_config.dart';

class ApiCallLogger {
  static final Map<String, ApiCallStats> _stats = {};

  /// API 호출 시작을 기록
  static void logStart(String apiName, {Map<String, dynamic>? params}) {
    if (!AppConfig.enableApiLogging) return;

    final stats = _stats[apiName] ??= ApiCallStats(apiName);
    stats._startCall(params);

    // Verbose 로깅에서만 파라미터 출력
    final paramStr =
        AppConfig.enableVerboseLogging && params != null ? ' - $params' : '';

    AppLogger.info(
      'API START: $apiName$paramStr',
      tag: 'API',
    );
  }

  /// API 호출 완료를 기록
  static void logEnd(String apiName, {bool success = true, String? error}) {
    if (!AppConfig.enableApiLogging) return;

    final stats = _stats[apiName];
    if (stats != null) {
      stats._endCall(success, error);

      if (success) {
        AppLogger.info(
          'API END: $apiName - SUCCESS (${stats.lastCallDuration}ms)',
          tag: 'API',
        );
      } else {
        AppLogger.error(
          'API END: $apiName - ERROR: $error (${stats.lastCallDuration}ms)',
          tag: 'API',
        );
      }
    }
  }

  /// 중복 호출 감지 및 경고 (Verbose 모드에서만)
  static void logDuplicateWarning(String apiName, Duration timeSinceLastCall) {
    if (!AppConfig.enableVerboseLogging) return;

    if (timeSinceLastCall.inMilliseconds < 1000) {
      AppLogger.warning(
        'DUPLICATE CALL WARNING: $apiName called again within ${timeSinceLastCall.inMilliseconds}ms',
        tag: 'API',
      );
    }
  }

  /// 현재까지의 통계 출력
  static void printStats() {
    if (!AppConfig.enableApiLogging || _stats.isEmpty) return;

    AppLogger.info('=== API Call Statistics ===', tag: 'API');

    for (final stats in _stats.values) {
      AppLogger.info(
        '${stats.apiName}: ${stats.totalCalls} calls, '
        'avg: ${stats.averageDuration}ms, '
        'success: ${stats.successRate.toStringAsFixed(1)}%',
        tag: 'API',
      );
    }

    AppLogger.info('==========================', tag: 'API');
  }

  /// 특정 API의 상세 통계 조회
  static ApiCallStats? getStats(String apiName) => _stats[apiName];

  /// 모든 통계 초기화
  static void clearStats() => _stats.clear();

  /// 현재 활성 호출 수 확인
  static int getActiveCalls() {
    return _stats.values
        .map((stats) => stats.activeCalls)
        .fold(0, (sum, count) => sum + count);
  }
}

class ApiCallStats {
  final String apiName;
  int _totalCalls = 0;
  int _successCalls = 0;
  int _activeCalls = 0;
  final List<int> _durations = [];
  final List<String> _errors = [];
  DateTime? _lastCallStart;
  DateTime? _lastCallEnd;

  ApiCallStats(this.apiName);

  void _startCall(Map<String, dynamic>? params) {
    // 중복 호출 감지 (Verbose 모드에서만)
    if (_lastCallStart != null && _lastCallEnd != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastCallEnd!);
      ApiCallLogger.logDuplicateWarning(apiName, timeSinceLastCall);
    }

    _lastCallStart = DateTime.now();
    _activeCalls++;
    _totalCalls++;
  }

  void _endCall(bool success, String? error) {
    _lastCallEnd = DateTime.now();
    _activeCalls = (_activeCalls - 1).clamp(0, 1000);

    if (_lastCallStart != null) {
      final duration = _lastCallEnd!.difference(_lastCallStart!).inMilliseconds;
      _durations.add(duration);
    }

    if (success) {
      _successCalls++;
    } else if (error != null) {
      _errors.add(error);
    }
  }

  // Getters
  int get totalCalls => _totalCalls;
  int get successCalls => _successCalls;
  int get activeCalls => _activeCalls;
  int get failedCalls => _totalCalls - _successCalls;

  double get successRate =>
      _totalCalls > 0 ? (_successCalls / _totalCalls) * 100 : 0;

  int get averageDuration {
    if (_durations.isEmpty) return 0;
    return (_durations.reduce((a, b) => a + b) / _durations.length).round();
  }

  int? get lastCallDuration => _durations.isNotEmpty ? _durations.last : null;

  List<String> get recentErrors => _errors.take(5).toList();

  /// 통계를 Map으로 변환 (디버깅용)
  Map<String, dynamic> toMap() {
    return {
      'apiName': apiName,
      'totalCalls': totalCalls,
      'successCalls': successCalls,
      'failedCalls': failedCalls,
      'activeCalls': activeCalls,
      'successRate': successRate,
      'averageDuration': averageDuration,
      'lastCallDuration': lastCallDuration,
      'recentErrors': recentErrors,
    };
  }
}

/// API 호출을 자동으로 로깅하는 데코레이터
class ApiCallDecorator {
  /// Future를 감싸서 자동으로 로깅하는 유틸리티
  static Future<T> wrap<T>(
    String apiName,
    Future<T> Function() apiCall, {
    Map<String, dynamic>? params,
  }) async {
    ApiCallLogger.logStart(apiName, params: params);

    try {
      final result = await apiCall();
      ApiCallLogger.logEnd(apiName, success: true);
      return result;
    } catch (e) {
      ApiCallLogger.logEnd(apiName, success: false, error: e.toString());
      rethrow;
    }
  }
}