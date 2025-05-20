// lib/map/presentation/group_map_screen.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/group_member_location.dart';
import 'package:devlink_mobile_app/map/presentation/components/group_map_member_card.dart';
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

  // 위치 공유 동의 요청 상태 추적
  bool _hasShownLocationDialog = false;

  @override
  void didUpdateWidget(GroupMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 맵이 초기화되고 권한 요청 다이얼로그가 아직 표시되지 않았다면
    if (widget.state.isMapInitialized && !_hasShownLocationDialog) {
      _showLocationSharingDialog();
    }

    // state가 변경되었을 때 마커 업데이트
    if (oldWidget.state.memberLocations != widget.state.memberLocations &&
        widget.state.memberLocations is AsyncData) {
      _addMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.showLocationSharingDialog && !_hasShownLocationDialog) {
      _hasShownLocationDialog = true;

      // 다이얼로그를 비동기적으로 표시
      Future.microtask(() => _showLocationSharingDialog());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.state.groupName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 검색 반경 설정 버튼 추가
          IconButton(
            icon: const Icon(Icons.radar),
            tooltip: '검색 반경 설정',
            onPressed: () => _showRadiusSettingDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 네이버맵
          _buildNaverMap(),

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

          // 현재 검색 반경 표시 (필터 배지)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.radar,
                    size: 16,
                    color: AppColorStyles.primary100,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.state.searchRadius.toStringAsFixed(1)}km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColorStyles.primary100,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      },
      onMapTapped: (point, latLng) {
        widget.onAction(GroupMapAction.onMapTap(point, latLng));
      },
      onCameraIdle: () {
        if (_mapController != null) {
          _mapController!.getCameraPosition().then((position) {
            widget.onAction(GroupMapAction.onCameraChange(position));
          });
        }
      },
    );
  }

  // 위치 공유 동의 다이얼로그 표시
  void _showLocationSharingDialog() {
    _hasShownLocationDialog = true;

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false, // 배경 클릭으로 닫기 불가
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('위치 공유'),
            content: const Text(
              '그룹 내 다른 멤버들과 위치 정보를 공유하시겠습니까?\n'
              '공유에 동의하면 다른 그룹 멤버들이 귀하의 위치를 확인할 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 지도 화면도 닫기
                },
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAction(
                    const GroupMapAction.requestLocationPermission(),
                  );
                  _showRadiusSettingDialog(); // 위치 공유 동의 후 검색 반경 설정 다이얼로그 표시
                },
                child: const Text('동의'),
              ),
            ],
          );
        },
      );
    });
  }

  // 검색 반경 설정 다이얼로그 표시
  void _showRadiusSettingDialog() {
    double tempRadius = widget.state.searchRadius;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('검색 반경 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('다른 멤버의 위치 정보를 확인할 반경을 설정하세요.'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('5km'),
                      Text(
                        '${tempRadius.toStringAsFixed(1)}km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColorStyles.primary100,
                        ),
                      ),
                      const Text('10km'),
                    ],
                  ),
                  Slider(
                    value: tempRadius,
                    min: 5.0,
                    max: 10.0,
                    divisions: 10,
                    activeColor: AppColorStyles.primary100,
                    onChanged: (value) {
                      setState(() {
                        tempRadius = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onAction(
                      GroupMapAction.updateSearchRadius(tempRadius),
                    );
                  },
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 마커 추가 메서드
  void _addMarkers() {
    if (_mapController == null || widget.state.memberLocations is! AsyncData)
      return;

    // 기존 마커 모두 제거 - 실제 API에 맞게 수정 필요
    // TODO: 네이버 맵 마커 제거 로직 구현

    final locations =
        (widget.state.memberLocations as AsyncData<List<GroupMemberLocation>>)
            .value;

    // 마커 추가 - 실제 API에 맞게 수정 필요
    for (final member in locations) {
      // TODO: 네이버 맵 마커 추가 로직 구현
      // 예시:
      // final marker = NMarker(
      //   id: member.memberId,
      //   position: NLatLng(member.latitude, member.longitude),
      // );
      // marker.setOnTapListener((_) {
      //   _onMarkerTapped(member.memberId);
      // });
      // _mapController!.addOverlay(marker);
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
