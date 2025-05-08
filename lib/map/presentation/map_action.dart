import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/map_marker.dart';
import 'package:devlink_mobile_app/map/domain/module/filter_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_action.freezed.dart';

@freezed
class MapAction with _$MapAction {
  // 초기화 및 권한 관련
  const factory MapAction.initialize() = Initialize;
  const factory MapAction.requestLocationPermission() =
      RequestLocationPermission;

  // 위치 관련
  const factory MapAction.getCurrentLocation() = GetCurrentLocation;
  const factory MapAction.updateSearchRadius(double radius) =
      UpdateSearchRadius;
  const factory MapAction.toggleTrackingMode() = ToggleTrackingMode;

  // 지도 제어
  const factory MapAction.changeZoomLevel(double level) = ChangeZoomLevel;
  const factory MapAction.onMapMoved(Location centerLocation) = OnMapMoved;
  const factory MapAction.onMapTap(Location location) = OnMapTap;

  // 마커 및 필터 관련
  const factory MapAction.selectMarker(MapMarker marker) = SelectMarker;
  const factory MapAction.clearSelection() = ClearSelection;
  const factory MapAction.changeFilter(FilterType filterType) = ChangeFilter;
  const factory MapAction.toggleClustering() = ToggleClustering;

  // 카드 뷰 관련
  const factory MapAction.selectCard(int index) = SelectCard;
  const factory MapAction.toggleCardView() = ToggleCardView;

  // 사용자 프로필 이동
  const factory MapAction.navigateToUserProfile(String userId) =
      NavigateToUserProfile;
  const factory MapAction.navigateToGroupDetail(String groupId) =
      NavigateToGroupDetail;
}
