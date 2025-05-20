// lib/map/presentation/group_map_screen.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/presentation/components/group_map_member_card.dart';
import 'package:devlink_mobile_app/map/presentation/components/radius_slider.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_action.dart';
import 'package:devlink_mobile_app/map/presentation/group_map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GroupMapScreen extends StatefulWidget {
  final GroupMapState state;
  final void Function(GroupMapAction action) onAction;

  const GroupMapScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupMapScreen> createState() => _GroupMapScreenState();
}

class _GroupMapScreenState extends State<GroupMapScreen> {
  // 컨트롤러 변수 추가
  NaverMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.state.groupName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 네이버맵
          _buildNaverMap(),

          // 검색 반경 슬라이더
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: RadiusSlider(
              radius: widget.state.searchRadius,
              onRadiusChanged:
                  (radius) => widget.onAction(
                    GroupMapAction.updateSearchRadius(radius),
                  ),
            ),
          ),

          // 현재 위치 버튼
          Positioned(
            bottom: widget.state.selectedMember != null ? 120 : 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor:
                  widget.state.isTrackingMode
                      ? AppColorStyles.primary100
                      : Colors.white,
              onPressed:
                  () => widget.onAction(
                    const GroupMapAction.toggleTrackingMode(),
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

          // 선택된 멤버 카드
          if (widget.state.selectedMember != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GroupMapMemberCard(
                member: widget.state.selectedMember!,
                onProfileTap:
                    () => widget.onAction(
                      GroupMapAction.navigateToMemberProfile(
                        widget.state.selectedMember!.memberId,
                      ),
                    ),
                onClose:
                    () =>
                        widget.onAction(const GroupMapAction.clearSelection()),
              ),
            ),

          // 에러 메시지
          if (widget.state.errorMessage != null)
            _buildErrorMessage(widget.state.errorMessage!),

          // 로딩 인디케이터
          if (widget.state.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // 네이버맵 위젯
  Widget _buildNaverMap() {
    return NaverMap(
      options: const NaverMapViewOptions(
        indoorEnable: true,
        locationButtonEnable: false, // 기본 위치 버튼 비활성화 (커스텀 버튼 사용)
      ),
      onMapReady: (controller) {
        _mapController = controller; // 컨트롤러 저장
        widget.onAction(GroupMapAction.onMapInitialized(controller));
        _addMarkers(); // 마커 추가
      },
      onMapTapped: (point, latLng) {
        widget.onAction(GroupMapAction.onMapTap(point, latLng));
      },
      // 카메라 변경 이벤트 - NaverMap 패키지의 최신 API에 맞게 수정 필요
      onCameraIdle: () {
        if (_mapController != null) {
          _mapController!.getCameraPosition().then((position) {
            widget.onAction(GroupMapAction.onCameraChange(position));
          });
        }
      },
    );
  }

  // 마커 추가 메서드
  void _addMarkers() {
    if (_mapController == null || widget.state.memberLocations is! AsyncData)
      return;

    // 기존 마커 모두 제거 - 실제 API에 맞게 수정 필요
    // _mapController!.clearOverlays();

    final locations =
        (widget.state.memberLocations as AsyncData<List<GroupMemberLocation>>)
            .value;

    // 마커 추가 - 실제 API에 맞게 수정 필요
    for (final member in locations) {
      // 마커 생성 코드는 네이버 맵 패키지 API에 맞게 수정 필요
    }
  }

  // 마커 탭 이벤트 처리
  void _onMarkerTapped(String memberId) {
    if (widget.state.memberLocations is! AsyncData) return;

    final locations =
        (widget.state.memberLocations as AsyncData<List<GroupMemberLocation>>)
            .value;
    final tappedMember = locations.firstWhere(
      (member) => member.memberId == memberId,
      orElse: () => throw StateError('멤버를 찾을 수 없습니다: $memberId'),
    );

    widget.onAction(GroupMapAction.onMemberMarkerTap(tappedMember));
  }

  // 에러 메시지 위젯
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
