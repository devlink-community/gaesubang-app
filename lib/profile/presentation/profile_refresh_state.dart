import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_refresh_state.g.dart';

@riverpod
class ProfileRefreshState extends _$ProfileRefreshState {
  @override
  bool build() => false;

  /// 프로필 갱신 필요함을 표시
  void markForRefresh() {
    state = true;
  }

  /// 프로필 갱신 완료됨을 표시
  void markRefreshed() {
    state = false;
  }

  /// 현재 갱신이 필요한지 확인
  bool get needsRefresh => state;
}
