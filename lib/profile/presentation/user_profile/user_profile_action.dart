// lib/profile/presentation/user_profile/user_profile_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_action.freezed.dart';

@freezed
sealed class UserProfileAction with _$UserProfileAction {
  // 사용자 ID 설정 및 프로필 로드
  const factory UserProfileAction.loadUserProfile(String userId) =
      LoadUserProfile;

  // 프로필 새로고침
  const factory UserProfileAction.refreshProfile() = RefreshProfile;

  // 팔로우/언팔로우 토글 (향후 확장용)
  const factory UserProfileAction.toggleFollow() = ToggleFollow;

  // 에러 메시지 클리어
  const factory UserProfileAction.clearError() = ClearError;

  // 성공 메시지 클리어
  const factory UserProfileAction.clearSuccess() = ClearSuccess;
}
