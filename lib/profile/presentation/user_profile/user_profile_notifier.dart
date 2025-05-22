// lib/profile/presentation/user_profile/user_profile_notifier.dart

import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_action.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'get_user_profile_usecase.dart';

part 'user_profile_notifier.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  late final GetUserProfileUseCase _getUserProfileUseCase;
  String _currentUserId = '';

  @override
  UserProfileState build() {
    _getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);

    return const UserProfileState();
  }

  Future<void> onAction(UserProfileAction action) async {
    switch (action) {
      case LoadUserProfile(:final userId):
        await _loadUserProfile(userId);

      case RefreshProfile():
        if (_currentUserId.isNotEmpty) {
          await _loadUserProfile(_currentUserId);
        }

      case ToggleFollow():
        // 향후 팔로우 기능 구현 시 사용
        break;

      case ClearError():
        state = state.copyWith(errorMessage: null);

      case ClearSuccess():
        state = state.copyWith(successMessage: null);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    _currentUserId = userId;

    // 로딩 상태 설정
    state = state.copyWith(
      userProfile: const AsyncValue.loading(),
      isLoading: true,
      errorMessage: null,
    );

    try {
      // 사용자 프로필 조회
      final result = await _getUserProfileUseCase.execute(userId);

      switch (result) {
        case AsyncData(:final value):
          state = state.copyWith(
            userProfile: AsyncData(value),
            isLoading: false,
          );

        case AsyncError(:final error):
          state = state.copyWith(
            userProfile: AsyncError(error, StackTrace.current),
            isLoading: false,
            errorMessage: '사용자 프로필을 불러올 수 없습니다.',
          );

        case AsyncLoading():
          // 이미 로딩 상태로 설정됨
          break;
      }
    } catch (e, st) {
      state = state.copyWith(
        userProfile: AsyncError(e, st),
        isLoading: false,
        errorMessage: '사용자 프로필 로드 중 오류가 발생했습니다.',
      );
    }
  }
}
