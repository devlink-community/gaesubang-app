import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const SettingsState({
    // 로그아웃 처리 상태
    this.logoutResult = const AsyncData(null),

    // 회원탈퇴 처리 상태
    this.deleteAccountResult = const AsyncData(null),

    // 앱 버전 정보
    this.appVersion,

    // 업데이트 필요 여부
    this.isUpdateAvailable,
  });

  final AsyncValue<void> logoutResult;
  final AsyncValue<void> deleteAccountResult;
  final String? appVersion;
  final bool? isUpdateAvailable;
}
