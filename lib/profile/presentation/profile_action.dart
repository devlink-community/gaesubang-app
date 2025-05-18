import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_action.freezed.dart';

@freezed
sealed class ProfileAction with _$ProfileAction {
  /// 톱니바퀴(설정) 아이콘 클릭
  const factory ProfileAction.openSettings() = OpenSettings;

  /// 데이터 새로고침
  const factory ProfileAction.refresh() = RefreshProfile;
}
