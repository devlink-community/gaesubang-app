import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/presentation/components/filter_tabs.dart';
import 'package:devlink_mobile_app/map/presentation/components/nearby_card_view.dart';
import 'package:devlink_mobile_app/map/presentation/components/radius_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:devlink_mobile_app/map/presentation/map_action.dart';
import 'package:devlink_mobile_app/map/presentation/map_state.dart';

class MapScreen extends StatefulWidget {
  final MapState state;
  final void Function(MapAction action) onAction;

  const MapScreen({super.key, required this.state, required this.onAction});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지도')),
      body: Column(
        children: [
          // 필터 탭 (모두/사용자/그룹)
          FilterTabs(
            selectedFilter: widget.state.selectedFilter,
            onFilterChanged:
                (filterType) =>
                    widget.onAction(MapAction.changeFilter(filterType)),
          ),

          // 검색 반경 슬라이더
          RadiusSlider(
            radius: widget.state.searchRadius,
            onRadiusChanged:
                (radius) =>
                    widget.onAction(MapAction.updateSearchRadius(radius)),
          ),

          // 지도 영역 (Expanded로 확장)
          Expanded(
            child: Stack(
              children: [
                // 네이버 지도
                NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(37.5666102, 126.9783881), // 서울시청 좌표
                      zoom: widget.state.zoomLevel,
                    ),
                    indoorEnable: true,
                    locationButtonEnable: true,
                    consumeSymbolTapEvents: false,
                    rotationGesturesEnable: false, // 회전 안됨
                    tiltGesturesEnable: false, // 기울기 안됨
                    zoomGesturesFriction: 1.0, // 줌 마찰계수
                    minZoom: 10, // default is 0
                    maxZoom: 16, // default is 21
                    maxTilt: 30, // default is 63
                    extent: NLatLngBounds(
                      // 지도 영역을 한반도 인근으로 제한
                      southWest: NLatLng(31.43, 122.37),
                      northEast: NLatLng(44.35, 132.0),
                    ),

                    mapType: NMapType.basic,
                  ),
                  forceGesture: true,

                  /// 지도 재스처 이벤트를 우선순위
                  onMapReady: (controller) {
                    _mapController = controller;
                    print("네이버맵 준비 완료!");
                  },
                  onMapTapped: (point, latLng) {
                    // 지도 탭 이벤트 처리
                    final location = NLatLng(latLng.latitude, latLng.longitude);
                    widget.onAction(
                      MapAction.onMapTap(
                        Location(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        ),
                      ),
                    );
                  },

                  onSymbolTapped: (symbol) {},
                  onCameraChange: (position, reason) {},
                  onCameraIdle: () {},
                  onSelectedIndoorChanged: (indoor) {},
                ),

                // 현재 위치 버튼 (우측 하단)
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor:
                        widget.state.isTrackingMode
                            ? AppColorStyles.primary100
                            : Colors.white,
                    onPressed:
                        () => widget.onAction(
                          const MapAction.toggleTrackingMode(),
                        ),
                    child: Icon(
                      Icons.my_location,
                      color:
                          widget.state.isTrackingMode
                              ? Colors.white
                              : AppColorStyles.primary100,
                    ),
                  ),
                ),

                // 에러 메시지 (있을 경우)
                if (widget.state.errorMessage != null)
                  _buildErrorMessage(widget.state.errorMessage!),
              ],
            ),
          ),

          // 하단 카드 뷰
          NearbyCardView(
            state: widget.state,
            onCardSelected:
                (index) => widget.onAction(MapAction.selectCard(index)),
            onUserProfileTap:
                (userId) =>
                    widget.onAction(MapAction.navigateToUserProfile(userId)),
            onGroupDetailTap:
                (groupId) =>
                    widget.onAction(MapAction.navigateToGroupDetail(groupId)),
            onToggle: () => widget.onAction(const MapAction.toggleCardView()),
          ),
        ],
      ),
    );
  }

  // void _updateMapWithState() {
  //   if (_mapController == null) return;

  //   // 여기서 상태에 따라 지도 업데이트 (마커 추가 등)
  //   // 현재 위치 표시 등의 작업을 수행

  //   // 예: 현재 위치가 있으면 그 위치로 이동
  //   if (widget.state.currentLocation is AsyncData) {
  //     final location = (widget.state.currentLocation as AsyncData<Location>).value;
  //     _mapController!.(
  //       NCameraUpdate.withParams(
  //         target: NLatLng(location.latitude, location.longitude),
  //         zoom: widget.state.zoomLevel,
  //       ),
  //     );
  //   }
  // }

  Widget _buildErrorMessage(String message) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
