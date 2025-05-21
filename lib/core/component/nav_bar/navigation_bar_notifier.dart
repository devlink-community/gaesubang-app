// lib/core/component/navigation_bar_notifier.dart
import 'package:devlink_mobile_app/auth/domain/usecase/get_current_user_use_case.dart';
import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/event/app_event.dart';
import 'package:devlink_mobile_app/core/event/app_event_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_bar_notifier.g.dart';

@riverpod
class NavigationBarNotifier extends _$NavigationBarNotifier {
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  @override
  String? build() {
    _getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);

    // 프로필 이벤트 감지하여 이미지 URL 갱신
    ref.listen(appEventNotifierProvider, (previous, current) {
      final events = current;
      for (final event in events) {
        if (event is ProfileUpdated) {
          _updateProfileImage();
          break;
        }
      }
    });

    // 초기 프로필 이미지 로드
    _updateProfileImage();

    return null; // 초기값은 null
  }

  // 현재 프로필 이미지 URL 불러오기
  Future<void> _updateProfileImage() async {
    final result = await _getCurrentUserUseCase.execute();
    if (result case AsyncData(:final value)) {
      if (value.image.isNotEmpty) {
        state = value.image;
      }
    }
  }
}
