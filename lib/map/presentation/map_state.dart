import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/domain/model/map_marker.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';
import 'package:devlink_mobile_app/map/module/filter_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'map_state.freezed.dart';

@freezed
class MapState with _$MapState {
  const MapState({
    // 현재 사용자 위치
    this.currentLocation = const AsyncValue.loading(),

    // 주변 사용자/그룹 정보
    this.nearbyItems = const AsyncValue.loading(),

    // 선택된 맵 마커
    this.selectedMarker,

    // 검색 반경 (km)
    this.searchRadius = 5.0,

    // 지도 확대/축소 레벨
    this.zoomLevel = 14.0,

    // 지도 관련 상태
    this.isTrackingMode = false,
    this.isMapInitialized = false,

    // 위치 권한 상태
    this.hasLocationPermission = false,
    this.isLocationServiceEnabled = false,

    // 필터 상태
    this.selectedFilter = FilterType.all,

    // 하단 카드 관련
    this.isCardViewExpanded = false,
    this.selectedCardIndex = -1,

    // 클러스터링 활성화 여부
    this.isClusteringEnabled = true,

    // 에러 메시지
    this.errorMessage,
  });

  final AsyncValue<Location> currentLocation;
  final AsyncValue<NearByItems> nearbyItems;
  final MapMarker? selectedMarker;
  final double searchRadius;
  final double zoomLevel;
  final bool isTrackingMode;
  final bool isMapInitialized;
  final bool hasLocationPermission;
  final bool isLocationServiceEnabled;
  final FilterType selectedFilter;
  final bool isCardViewExpanded;
  final int selectedCardIndex;
  final bool isClusteringEnabled;
  final String? errorMessage;
}
