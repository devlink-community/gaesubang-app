// lib/core/utils/stream_listenable.dart 수정
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Stream을 Listenable로 변환하는 유틸리티 클래스
/// GoRouter의 refreshListenable에서 사용하여 상태 변화를 감지
class StreamListenable<T> extends ChangeNotifier {
  StreamListenable(Stream<T> stream) {
    _subscription = stream.listen(_onData, onError: _onError, onDone: _onDone);
  }

  StreamSubscription<T>? _subscription;
  T? _lastValue;

  /// 현재 캐시된 값 (있는 경우)
  T? get currentValue => _lastValue;

  /// 스트림에서 새 데이터를 받았을 때 처리
  void _onData(T data) {
    // 동일한 값이면 리스너에게 알리지 않음
    if (_lastValue == data) {
      if (kDebugMode) {
        print('StreamListenable: 동일한 값 무시 - $data');
      }
      return;
    }

    _lastValue = data;

    if (kDebugMode) {
      print('StreamListenable: 새 값 감지 - $data');
    }

    // 리스너들에게 변화 알림
    notifyListeners();
  }

  /// 스트림에서 에러가 발생했을 때 처리
  void _onError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('StreamListenable: 에러 발생 - $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// 스트림이 완료되었을 때 처리
  void _onDone() {
    if (kDebugMode) {
      print('StreamListenable: 스트림 완료');
    }
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

    // 부모 클래스의 dispose 호출
    super.dispose();
  }
}
