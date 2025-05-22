import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_event.dart';

part 'app_event_notifier.g.dart';

/// 앱 이벤트 발행-구독 시스템
@Riverpod(keepAlive: true)
class AppEventNotifier extends _$AppEventNotifier {
  final List<AppEvent> _events = [];

  @override
  List<AppEvent> build() => [];

  /// 이벤트 발행
  void emit(AppEvent event) {
    // 이벤트 추가 및 최대 20개 유지 (메모리 관리)
    _events.add(event);
    if (_events.length > 20) {
      _events.removeAt(0);
    }

    // 상태 업데이트 (새 이벤트 발행)
    state = List.from(_events);
  }

  /// 최근 이벤트 조회
  List<AppEvent> get recentEvents => List.unmodifiable(_events);

  /// 특정 타입의 이벤트 존재 여부 확인
  bool hasEventOfType<T extends AppEvent>() {
    return _events.any((event) => event is T);
  }

  /// 특정 포스트 관련 이벤트 존재 여부 확인
  bool hasPostEvent(String postId) {
    return _events.any(
      (event) =>
          event is PostUpdated && event.postId == postId ||
          event is PostLiked && event.postId == postId ||
          event is PostBookmarked && event.postId == postId ||
          event is CommentAdded && event.postId == postId,
    );
  }

  /// 모든 이벤트 초기화
  void clearAll() {
    _events.clear();
    state = [];
  }
}
