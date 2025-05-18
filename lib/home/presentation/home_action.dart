import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_action.freezed.dart';

@freezed
sealed class HomeAction with _$HomeAction {
  /// 데이터 새로고침
  const factory HomeAction.refresh() = RefreshHome;

  /// 공지사항 클릭
  const factory HomeAction.onTapNotice(String noticeId) = OnTapNotice;

  /// 그룹 클릭
  const factory HomeAction.onTapGroup(String groupId) = OnTapGroup;

  /// 인기 게시글 클릭
  const factory HomeAction.onTapPopularPost(String postId) = OnTapPopularPost;

  /// 설정 버튼 클릭
  const factory HomeAction.onTapSettings() = OnTapSettings;

  /// 알림 버튼 클릭
  const factory HomeAction.onTapNotification() = OnTapNotification;
}
