import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/location.dart';
import 'package:devlink_mobile_app/map/presentation/map_action.dart';
import 'package:devlink_mobile_app/map/presentation/map_state.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class MapScreen extends StatelessWidget {
  final MapState state;
  final void Function(MapAction action) onAction;

  const MapScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        actions: [
          // 클러스터링 토글 버튼
          IconButton(
            icon: Icon(
              state.isClusteringEnabled ? Icons.grid_view : Icons.grid_off,
              color: AppColorStyles.primary100,
            ),
            onPressed: () => onAction(const MapAction.toggleClustering()),
            tooltip: '클러스터링 ${state.isClusteringEnabled ? '끄기' : '켜기'}',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭 (모두/사용자/그룹)
          FilterTabs(
            selectedFilter: state.selectedFilter,
            onFilterChanged:
                (filterType) => onAction(MapAction.changeFilter(filterType)),
          ),

          // 검색 반경 슬라이더
          RadiusSlider(
            radius: state.searchRadius,
            onRadiusChanged:
                (radius) => onAction(MapAction.updateSearchRadius(radius)),
          ),

          // 지도 영역
          Expanded(
            child: Stack(
              children: [
                // 지도 위젯
                _buildMap(),

                // 현재 위치 버튼 (우측 하단)
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: _buildLocationButton(),
                ),

                // 에러 메시지 (있을 경우)
                if (state.errorMessage != null)
                  _buildErrorMessage(state.errorMessage!),
              ],
            ),
          ),

          // 하단 카드 뷰
          NearbyCardView(
            state: state,
            onCardSelected: (index) => onAction(MapAction.selectCard(index)),
            onUserProfileTap:
                (userId) => onAction(MapAction.navigateToUserProfile(userId)),
            onGroupDetailTap:
                (groupId) => onAction(MapAction.navigateToGroupDetail(groupId)),
            onToggle: () => onAction(const MapAction.toggleCardView()),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // 지도 위젯 구현
    // 실제로는 네이버 맵 또는 구글 맵 등 사용할 지도 라이브러리에 맞게 구현
    // 여기서는 기본 상태 기반 UI만 구현

    return GestureDetector(
      onTap:
          () => onAction(
            MapAction.onMapTap(
              state.currentLocation.valueOrNull ??
                  const Location(latitude: 0, longitude: 0),
            ),
          ),
      child: Stack(
        children: [
          // 지도 배경 (실제로는 지도 라이브러리로 대체)
          Container(
            color: Colors.grey[200],
            child: Center(
              child: switch (state.currentLocation) {
                AsyncData(:final value) => Text(
                  '현재 위치: ${value.latitude}, ${value.longitude}\n'
                  '검색 반경: ${state.searchRadius}km',
                  textAlign: TextAlign.center,
                ),
                AsyncError(:final error) => Text('위치 오류: $error'),
                AsyncLoading() => const CircularProgressIndicator(),
              },
            ),
          ),

          // 주변 항목 마커 (실제로는 지도 라이브러리의 마커로 구현)
          if (state.nearbyItems is AsyncData) _buildMarkers(),
        ],
      ),
    );
  }

  Widget _buildMarkers() {
    // 실제 구현에서는 지도 라이브러리의 마커로 구현
    // 여기서는 사용자 이해를 위한 설명만 표시
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '이 영역에 필터링된 마커가 표시됩니다.\n'
          '사용자와 그룹을 다른 색상으로 구분하며,\n'
          '클러스터링 기능이 적용됩니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            backgroundColor: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor:
          state.isTrackingMode ? AppColorStyles.primary100 : Colors.white,
      onPressed: () => onAction(const MapAction.toggleTrackingMode()),
      child: Icon(
        Icons.my_location,
        color: state.isTrackingMode ? Colors.white : AppColorStyles.primary100,
      ),
    );
  }

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
