// lib/core/utils/stream_listenable.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Stream을 Listenable로 변환하는 유틸리티 클래스
/// GoRouter의 refreshListenable에서 사용하여 상태 변화를 감지
class StreamListenable<T> extends ChangeNotifier {
  StreamListenable(Stream<T> stream) {
    _subscription = stream.listen((_) {
      // 스트림 값이 변할 때마다 리스너들에게 알림
      notifyListeners();
    });
  }

  StreamSubscription<T>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
