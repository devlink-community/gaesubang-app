import 'package:devlink_mobile_app/auth/domain/model/summary.dart'; // Summary 모델 임포트로 변경
import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const ProfileState({
    /// 프로필 정보 로딩/성공/실패 상태
    this.userProfile = const AsyncLoading(),

    /// 활동 요약 정보 로딩/성공/실패 상태 (FocusStats에서 Summary로 변경)
    this.summary = const AsyncLoading(),

    /// 중복 요청 방지를 위한 요청 ID
    this.activeRequestId,
  });

  final AsyncValue<User> userProfile;
  final AsyncValue<Summary> summary; // FocusTimeStats에서 Summary로 변경
  final int? activeRequestId;
}
