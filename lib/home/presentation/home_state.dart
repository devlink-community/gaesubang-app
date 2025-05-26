import 'package:devlink_mobile_app/auth/domain/model/user.dart';
import 'package:devlink_mobile_app/banner/domain/model/banner.dart';
import 'package:devlink_mobile_app/community/domain/model/post.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/home/domain/model/notice.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const HomeState({
    this.currentMember = const AsyncLoading(),
    this.notices = const AsyncLoading(),
    this.joinedGroups = const AsyncLoading(),
    this.popularPosts = const AsyncLoading(),
    this.activeBanner = const AsyncLoading(),
    this.totalStudyTimeMinutes = const AsyncLoading(),
    this.streakDays = const AsyncLoading(),
    this.unreadNotificationCount = const AsyncData(0), // 🆕 읽지 않은 알림 수 추가
  });

  @override
  final AsyncValue<User> currentMember;
  @override
  final AsyncValue<List<Notice>> notices;
  @override
  final AsyncValue<List<Group>> joinedGroups;
  @override
  final AsyncValue<List<Post>> popularPosts;
  @override
  final AsyncValue<Banner?> activeBanner;
  @override
  final AsyncValue<int> totalStudyTimeMinutes;
  @override
  final AsyncValue<int> streakDays;
  final AsyncValue<int> unreadNotificationCount; // 🆕 읽지 않은 알림 수

  // Helper getters
  String get currentMemberName => currentMember.valueOrNull?.nickname ?? '개발자';

  String? get currentMemberImage => currentMember.valueOrNull?.image;

  String get totalStudyTimeDisplay {
    final minutes = totalStudyTimeMinutes.valueOrNull ?? 0;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '$hours시간 $remainingMinutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$remainingMinutes분';
    }
  }

  String get streakDaysDisplay {
    final days = streakDays.valueOrNull ?? 0;
    return '$days일';
  }

  String get joinedGroupCountDisplay {
    final count = joinedGroups.valueOrNull?.length ?? 0;
    return '$count개';
  }

  // 🆕 읽지 않은 알림이 있는지 확인하는 getter
  bool get hasUnreadNotifications {
    final count = unreadNotificationCount.valueOrNull ?? 0;
    return count > 0;
  }
}
