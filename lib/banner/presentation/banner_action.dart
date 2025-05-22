import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner_action.freezed.dart';

@freezed
sealed class BannerAction with _$BannerAction {
  /// 배너 목록 로드
  const factory BannerAction.loadBanners() = LoadBanners;

  /// 배너 새로고침
  const factory BannerAction.refreshBanners() = RefreshBanners;

  /// 배너 클릭 (현재는 아무 동작 없음)
  const factory BannerAction.onTapBanner(String bannerId, String? linkUrl) = OnTapBanner;
}