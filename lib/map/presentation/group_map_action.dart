// lib/map/presentation/group_map_action.dart
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_map_action.freezed.dart';

@freezed
sealed class GroupMapAction with _$GroupMapAction {
  // 초기화 액션
  const factory GroupMapAction.initialize(String groupId, String groupName) =
      Initialize;

  // 위치 권한 요청
  const factory GroupMapAction.requestLocationPermission() =
      RequestLocationPermission;

  // 현재 위치 가져오기
  const factory GroupMapAction.getCurrentLocation() = GetCurrentLocation;

  // 위치 업데이트
  const factory GroupMapAction.updateLocation(
    double latitude,
    double longitude,
  ) = UpdateLocation;

  // 위치 추적 모드 토글
  const factory GroupMapAction.toggleTrackingMode() = ToggleTrackingMode;

  // 맵 초기화 완료
  const factory GroupMapAction.onMapInitialized(NaverMapController controller) =
      OnMapInitialized;

  // 맵 카메라 이동
  const factory GroupMapAction.onCameraChange(NCameraPosition position) =
      OnCameraChange;

  // 맵 탭 이벤트
  const factory GroupMapAction.onMapTap(NPoint point, NLatLng latLng) =
      OnMapTap;

  // 멤버 마커 탭 이벤트
  const factory GroupMapAction.onMemberMarkerTap(GroupMemberLocation member) =
      OnMemberMarkerTap;

  // 선택 해제
  const factory GroupMapAction.clearSelection() = ClearSelection;

  // 검색 반경 변경
  const factory GroupMapAction.updateSearchRadius(double radius) =
      UpdateSearchRadius;

  // 그룹 멤버 프로필로 이동
  const factory GroupMapAction.navigateToMemberProfile(String userId) =
      NavigateToMemberProfile;

  // 위치 공유 동의 액션
  const factory GroupMapAction.updateLocationSharingAgreement(
    bool agreed,
    double radius,
  ) = UpdateLocationSharingAgreement;

  // 위치 공유 동의 대화상자 표시 액션
  const factory GroupMapAction.showLocationSharingDialog() =
      ShowLocationSharingDialog;

  // 위치 공유 동의 대화상자 숨기기 액션
  const factory GroupMapAction.hideLocationSharingDialog() =
      HideLocationSharingDialog;
}
