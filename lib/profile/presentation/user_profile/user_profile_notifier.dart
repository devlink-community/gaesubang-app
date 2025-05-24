// lib/profile/presentation/user_profile/user_profile_notifier.dart

import 'package:devlink_mobile_app/auth/module/auth_di.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:devlink_mobile_app/core/utils/privacy_mask_util.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_action.dart';
import 'package:devlink_mobile_app/profile/presentation/user_profile/user_profile_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/domain/usecase/profile/get_user_profile_usecase.dart';

part 'user_profile_notifier.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  late final GetUserProfileUseCase _getUserProfileUseCase;
  String _currentUserId = '';

  @override
  UserProfileState build() {
    AppLogger.ui('UserProfileNotifier 초기화 시작');

    _getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);

    AppLogger.logState('사용자 프로필 UseCase 초기화', {
      'get_user_profile_usecase': 'initialized',
    });

    AppLogger.ui('UserProfileNotifier 초기화 완료');
    return const UserProfileState();
  }

  Future<void> onAction(UserProfileAction action) async {
    AppLogger.debug('사용자 프로필 액션 처리: ${action.runtimeType}');

    switch (action) {
      case LoadUserProfile(:final userId):
        AppLogger.ui('사용자 프로필 로드 요청: ${PrivacyMaskUtil.maskUserId(userId)}');
        await _loadUserProfile(userId);

      case RefreshProfile():
        if (_currentUserId.isNotEmpty) {
          AppLogger.ui(
            '현재 사용자 프로필 새로고침: ${PrivacyMaskUtil.maskUserId(_currentUserId)}',
          );
          await _loadUserProfile(_currentUserId);
        } else {
          AppLogger.warning('새로고침할 사용자 ID가 없음');
        }

      case ToggleFollow():
        AppLogger.debug('팔로우 토글 액션 (향후 구현 예정)');
        // 향후 팔로우 기능 구현 시 사용
        break;

      case ClearError():
        AppLogger.debug('에러 메시지 초기화');
        state = state.copyWith(errorMessage: null);

      case ClearSuccess():
        AppLogger.debug('성공 메시지 초기화');
        state = state.copyWith(successMessage: null);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    AppLogger.logBanner('사용자 프로필 조회 시작');
    final startTime = DateTime.now();

    AppLogger.logState('사용자 프로필 조회 요청', {
      'target_user_id': PrivacyMaskUtil.maskUserId(userId),
      'request_type': 'user_profile_load',
    });

    _currentUserId = userId;

    // 중복 요청 방지를 위한 요청 ID 생성
    final currentRequestId = DateTime.now().microsecondsSinceEpoch;
    AppLogger.logState('중복 요청 방지 설정', {
      'request_id': currentRequestId,
      'target_user_id': PrivacyMaskUtil.maskUserId(userId),
    });

    AppLogger.logStep(1, 4, '로딩 상태 설정 및 요청 ID 저장');
    // 로딩 상태 설정 + 요청 ID 저장
    state = state.copyWith(
      userProfile: const AsyncValue.loading(),
      isLoading: true,
      errorMessage: null,
      activeRequestId: currentRequestId,
      currentUserId: userId,
    );

    try {
      AppLogger.logStep(2, 4, '사용자 프로필 데이터 조회');
      // 사용자 프로필 조회
      final result = await _getUserProfileUseCase.execute(userId);

      // 다른 요청이 이미 시작됐다면 무시
      if (state.activeRequestId != currentRequestId) {
        AppLogger.warning(
          '다른 사용자 프로필 요청이 진행 중이므로 현재 요청 무시',
          error:
              'RequestID: $currentRequestId vs Current: ${state.activeRequestId}',
        );
        return;
      }

      AppLogger.logStep(3, 4, '사용자 프로필 조회 결과 처리');
      switch (result) {
        case AsyncData(:final value):
          AppLogger.ui('사용자 프로필 조회 성공');
          AppLogger.logState('조회된 사용자 프로필 정보', {
            'target_user_id': PrivacyMaskUtil.maskUserId(userId),
            'nickname': PrivacyMaskUtil.maskNickname(value.nickname),
            'email': PrivacyMaskUtil.maskEmail(value.email),
            'has_description': value.description.isNotEmpty,
            'has_position': value.position?.isNotEmpty ?? false,
            'has_skills': value.skills?.isNotEmpty ?? false,
            'has_image': value.image.isNotEmpty,
            'streak_days': value.streakDays,
          });

          // 요청 ID가 여전히 유효한지 한 번 더 확인
          if (state.activeRequestId == currentRequestId) {
            AppLogger.logStep(4, 4, '사용자 프로필 상태 업데이트');
            state = state.copyWith(
              userProfile: AsyncData(value),
              isLoading: false,
              activeRequestId: null, // 요청 완료 후 ID 초기화
            );

            final duration = DateTime.now().difference(startTime);
            AppLogger.logPerformance('사용자 프로필 조회', duration);
            AppLogger.logBox(
              '사용자 프로필 조회 완료',
              '사용자: ${PrivacyMaskUtil.maskNickname(value.nickname)}\n소요시간: ${duration.inMilliseconds}ms',
            );
          } else {
            AppLogger.warning(
              '요청 완료 시점에 다른 요청이 진행 중이므로 상태 업데이트 무시',
            );
          }

        case AsyncError(:final error):
          AppLogger.error('사용자 프로필 조회 실패', error: error);
          AppLogger.logState('사용자 프로필 조회 실패 상세', {
            'target_user_id': PrivacyMaskUtil.maskUserId(userId),
            'error_type': error.runtimeType.toString(),
            'request_id': currentRequestId,
          });

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
          AppLogger.debug('사용자 프로필 로딩 중 (상태 유지)');
          // 이미 로딩 상태로 설정됨
          break;
      }
    } catch (e, st) {
      AppLogger.error('사용자 프로필 조회 중 예외 발생', error: e, stackTrace: st);
      AppLogger.logState('사용자 프로필 조회 예외 상세', {
        'target_user_id': PrivacyMaskUtil.maskUserId(userId),
        'error_type': e.runtimeType.toString(),
        'request_id': currentRequestId,
      });

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
