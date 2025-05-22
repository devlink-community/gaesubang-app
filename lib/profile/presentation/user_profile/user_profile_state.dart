// lib/profile/presentation/user_profile/user_profile_state.dart
import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'user_profile_state.freezed.dart';

@freezed
class UserProfileState with _$UserProfileState {
  const UserProfileState({
    // 사용자 프로필 정보
    this.userProfile = const AsyncValue.loading(),

    // 팔로우 상태 (향후 확장용)
    this.isFollowing = false,

    // 로딩 상태
    this.isLoading = false,

    // 에러 메시지
    this.errorMessage,

    // 성공 메시지
    this.successMessage,

    // 중복 요청 방지를 위한 요청 ID
    this.activeRequestId,

    // 현재 로드된 사용자 ID
    this.currentUserId,
  });

  final AsyncValue<Member> userProfile;
  final bool isFollowing;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final int? activeRequestId;
  final String? currentUserId;
}
