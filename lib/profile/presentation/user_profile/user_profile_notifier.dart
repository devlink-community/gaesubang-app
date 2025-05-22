// lib/profile/presentation/user_profile/user_profile_notifier.dart

import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_action.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_state.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('🚀 UserProfileNotifier: 사용자 프로필 로드 시작 - userId: $userId');

    _currentUserId = userId;

    // 중복 요청 방지를 위한 요청 ID 생성
    final currentRequestId = DateTime.now().microsecondsSinceEpoch;
    debugPrint('🔄 UserProfileNotifier: 요청 ID 생성: $currentRequestId');

    // 로딩 상태 설정 + 요청 ID 저장
    state = state.copyWith(
      userProfile: const AsyncValue.loading(),
      isLoading: true,
      errorMessage: null,
      activeRequestId: currentRequestId,
      currentUserId: userId,
    );

    try {
      // 사용자 프로필 조회
      final result = await _getUserProfileUseCase.execute(userId);

      // 다른 요청이 이미 시작됐다면 무시
      if (state.activeRequestId != currentRequestId) {
        debugPrint(
          '⚠️ UserProfileNotifier: 다른 요청이 진행 중이므로 현재 요청($currentRequestId) 무시',
        );
        return;
      }

      switch (result) {
        case AsyncData(:final value):
          debugPrint('✅ UserProfileNotifier: 사용자 프로필 로드 성공: ${value.nickname}');

          // 요청 ID가 여전히 유효한지 한 번 더 확인
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: AsyncData(value),
              isLoading: false,
              activeRequestId: null, // 요청 완료 후 ID 초기화
            );
          } else {
            debugPrint(
              '⚠️ UserProfileNotifier: 요청 완료 시점에 다른 요청이 진행 중이므로 상태 업데이트 무시',
            );
          }

        case AsyncError(:final error):
          debugPrint('❌ UserProfileNotifier: 사용자 프로필 로드 실패: $error');

          // 요청 ID가 여전히 유효한지 확인 후 에러 상태 설정
          if (state.activeRequestId == currentRequestId) {
            state = state.copyWith(
              userProfile: AsyncError(error, StackTrace.current),
              isLoading: false,
              errorMessage: '사용자 프로필을 불러올 수 없습니다.',
              activeRequestId: null, // 에러 발생 후 ID 초기화
            );
          }

        case AsyncLoading():
          // 이미 로딩 상태로 설정됨
          break;
      }
    } catch (e, st) {
      debugPrint('❌ UserProfileNotifier: 사용자 프로필 로드 중 예외 발생: $e');

      // 예외 발생 시에도 요청 ID 확인
      if (state.activeRequestId == currentRequestId) {
        state = state.copyWith(
          userProfile: AsyncValue.error(e, st),
          isLoading: false,
          errorMessage: '사용자 프로필 로드 중 오류가 발생했습니다.',
          activeRequestId: null, // 예외 발생 후 ID 초기화
        );
      }
    }
  }
}
