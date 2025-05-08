// lib/map/presentation/components/nearby_card_view.dart
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/map/domain/model/map_marker.dart';
import 'package:devlink_mobile_app/map/domain/model/near_by_items.dart';
import 'package:devlink_mobile_app/map/module/filter_type.dart';
import 'package:devlink_mobile_app/map/presentation/map_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NearbyCardView extends StatelessWidget {
  final MapState state;
  final Function(int) onCardSelected;
  final Function(String) onUserProfileTap;
  final Function(String) onGroupDetailTap;
  final VoidCallback onToggle;

  const NearbyCardView({
    super.key,
    required this.state,
    required this.onCardSelected,
    required this.onUserProfileTap,
    required this.onGroupDetailTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final height = state.isCardViewExpanded ? 300.0 : 120.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 헤더 (토글 핸들)
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorStyles.gray60,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // 내용
          Expanded(child: _buildCardContent()),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    switch (state.nearbyItems) {
      case AsyncData(:final value):
        return _buildNearbyItems(value);
      case AsyncError(:final error):
        return Center(
          child: Text(
            '주변 항목을 불러오는 중 오류가 발생했습니다.\n$error',
            textAlign: TextAlign.center,
          ),
        );
      case AsyncLoading():
        return const Center(child: CircularProgressIndicator());
      // 모든 케이스를 처리하기 위한 기본 케이스 추가
      default:
        return const Center(child: Text('오류', textAlign: TextAlign.center));
    }
  }

  Widget _buildNearbyItems(NearByItems items) {
    final markersList = <MapMarker>[];

    // 필터에 따라 마커 목록 구성
    switch (state.selectedFilter) {
      case FilterType.all:
        markersList.addAll([...items.groups, ...items.users]);
      case FilterType.groups:
        markersList.addAll(items.groups);
      case FilterType.users:
        markersList.addAll(items.users);
    }

    if (markersList.isEmpty) {
      return Center(
        child: Text(
          '주변에 ${_getFilterName(state.selectedFilter)}이(가) 없습니다.',
          style: AppTextStyles.body1Regular,
        ),
      );
    }

    return ListView.builder(
      itemCount: markersList.length,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final marker = markersList[index];
        return _buildMarkerCard(marker, index);
      },
    );
  }

  Widget _buildMarkerCard(MapMarker marker, int index) {
    final isSelected = state.selectedCardIndex == index;

    return GestureDetector(
      onTap: () => onCardSelected(index),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColorStyles.primary60 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColorStyles.primary100 : AppColorStyles.gray40,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: AppColorStyles.gray40,
              ),
              child: Center(
                child:
                    marker.imageUrl.isEmpty
                        ? Icon(
                          marker.type == MarkerType.user
                              ? Icons.person
                              : Icons.group,
                          size: 40,
                          color: AppColorStyles.gray80,
                        )
                        : ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            marker.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                marker.type == MarkerType.user
                                    ? Icons.person
                                    : Icons.group,
                                size: 40,
                                color: AppColorStyles.gray80,
                              );
                            },
                          ),
                        ),
              ),
            ),

            // 정보 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marker.title,
                    style: AppTextStyles.subtitle1Bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    marker.description,
                    style: AppTextStyles.body2Regular,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (marker.type == MarkerType.group &&
                      state.isCardViewExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 14,
                            color: AppColorStyles.primary100,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${marker.memberCount}명 / ${marker.limitMemberCount}명',
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColorStyles.primary100,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 버튼 영역 (확장 시에만 표시)
                  if (state.isCardViewExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (marker.type == MarkerType.user) {
                              onUserProfileTap(marker.id);
                            } else {
                              onGroupDetailTap(marker.id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorStyles.primary100,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            marker.type == MarkerType.user ? '프로필 보기' : '그룹 보기',
                            style: AppTextStyles.captionRegular.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterName(FilterType filterType) {
    switch (filterType) {
      case FilterType.all:
        return '그룹 또는 사용자';
      case FilterType.groups:
        return '그룹';
      case FilterType.users:
        return '사용자';
    }
  }
}
