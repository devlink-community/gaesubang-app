// lib/core/utils/stream_listenable.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart'; // AuthState import 추가

/// Stream을 Listenable로 변환하는 유틸리티 클래스
/// GoRouter의 refreshListenable에서 사용하여 상태 변화를 감지
///
/// ✅ 최적화 포인트:
/// - 마지막 상태를 캐시하여 불필요한 알림 방지
/// - 동일한 상태로의 변화는 무시
/// - 메모리 누수 방지를 위한 안전한 dispose
class StreamListenable<T> extends ChangeNotifier {
  StreamListenable(Stream<T> stream) {
    _subscription = stream.listen(_onData, onError: _onError, onDone: _onDone);
  }

  StreamSubscription<T>? _subscription;
  T? _lastValue;
  Object? _lastError;
  bool _hasError = false;
  bool _isDone = false;

  /// 현재 캐시된 값 (있는 경우)
  T? get currentValue => _lastValue;

  /// 마지막으로 발생한 에러 (있는 경우)
  Object? get lastError => _lastError;

  /// 에러 상태인지 확인
  bool get hasError => _hasError;

  /// 스트림이 완료되었는지 확인
  bool get isDone => _isDone;

  /// 스트림에서 새 데이터를 받았을 때 처리
  void _onData(T data) {
    // ✅ 최적화: 동일한 값이면 리스너에게 알리지 않음
    if (_lastValue == data) {
      if (kDebugMode) {
        print('StreamListenable: 동일한 값 무시 - $data');
      }
      return;
    }

    _lastValue = data;
    _hasError = false;
    _lastError = null;

    if (kDebugMode) {
      print('StreamListenable: 새 값 감지 - $data');
    }

    // 리스너들에게 변화 알림
    notifyListeners();
  }

  /// 스트림에서 에러가 발생했을 때 처리
  void _onError(Object error, StackTrace? stackTrace) {
    _lastError = error;
    _hasError = true;

    if (kDebugMode) {
      print('StreamListenable: 에러 발생 - $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }

    // 에러도 상태 변화이므로 리스너에게 알림
    notifyListeners();
  }

  /// 스트림이 완료되었을 때 처리
  void _onDone() {
    _isDone = true;

    if (kDebugMode) {
      print('StreamListenable: 스트림 완료');
    }

    // 완료도 상태 변화이므로 리스너에게 알림
    notifyListeners();
  }

  /// 수동으로 스트림을 다시 시작하는 메서드 (필요한 경우)
  void refresh() {
    if (kDebugMode) {
      print('StreamListenable: 수동 새로고침 요청');
    }
    notifyListeners();
  }

  /// 현재 상태의 디버그 정보를 출력
  void printDebugInfo() {
    if (!kDebugMode) return;

    print('=== StreamListenable Debug Info ===');
    print('hasValue: ${_lastValue != null}');
    print('lastValue: $_lastValue');
    print('hasError: $_hasError');
    print('lastError: $_lastError');
    print('isDone: $_isDone');
    print('hasListeners: $hasListeners');
    print('===============================');
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('StreamListenable: dispose 호출');
    }

    // 스트림 구독 해제
    _subscription?.cancel();
    _subscription = null;

    // 캐시된 값들 초기화
    _lastValue = null;
    _lastError = null;
    _hasError = false;
    _isDone = false;

    // 부모 클래스의 dispose 호출
    super.dispose();
  }
}

/// 인증 상태 전용 StreamListenable 확장
/// 더 구체적인 타입 안전성과 편의 메서드 제공
class AuthStateListenable extends StreamListenable<AuthState> {
  AuthStateListenable(Stream<AuthState> authStateStream)
    : super(authStateStream);

  /// 현재 인증되어 있는지 확인 (수정된 버전)
  bool get isAuthenticated {
    final currentState = _lastValue;
    if (currentState == null) return false;

    // ✅ AuthState의 확장 메서드 직접 사용
    return currentState.isAuthenticated;
  }

  /// 현재 사용자 정보 (있는 경우) (수정된 버전)
  dynamic get currentUser {
    final currentState = _lastValue;
    if (currentState == null) return null;

    // ✅ AuthState의 확장 메서드 직접 사용
    return currentState.user;
  }

  /// 로딩 중인지 확인 (수정된 버전)
  bool get isLoading {
    final currentState = _lastValue;
    if (currentState == null) return true; // 아직 첫 값을 받지 못함

    // ✅ AuthState의 확장 메서드 직접 사용
    return currentState.isLoading;
  }

  @override
  void printDebugInfo() {
    if (!kDebugMode) return;

    print('=== AuthStateListenable Debug Info ===');
    print('isAuthenticated: $isAuthenticated');
    print('isLoading: $isLoading');
    print('currentUser: ${currentUser != null ? 'Present' : 'Null'}');
    super.printDebugInfo();
  }
}
