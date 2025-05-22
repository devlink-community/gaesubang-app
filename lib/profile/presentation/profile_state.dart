import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/model/focus_time_stats.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const ProfileState({
    /// 프로필 정보 로딩/성공/실패 상태
    this.userProfile = const AsyncLoading(),

    /// 통계 정보 로딩/성공/실패 상태
    this.focusStats = const AsyncLoading(),

    /// 중복 요청 방지를 위한 요청 ID
    this.activeRequestId,
  });

  final AsyncValue<Member> userProfile;
  final AsyncValue<FocusTimeStats> focusStats;
  final int? activeRequestId;
}
