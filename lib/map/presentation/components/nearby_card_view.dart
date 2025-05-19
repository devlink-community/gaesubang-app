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
    // 화면 크기에 따라 동적으로 높이 조정
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 축소 상태에서는 최소 높이만 확보하고, 확장 시에는 화면의 40%까지만 차지하도록 조정
    // 축소 상태 높이를 줄여서 오버플로우 방지
    final height =
        state.isCardViewExpanded
            ? screenHeight * 0.4
            : 80.0 + bottomPadding; // 바텀 패딩 고려하여 높이 설정

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.1,
            ), // withValues → withOpacity 수정
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 최소 사이즈 사용
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

          // 내용 - SafeArea로 감싸서 안전 영역 확보
          Expanded(
            child: SafeArea(
              top: false, // 상단은 이미 안전지대이므로 제외
              child: _buildCardContent(),
            ),
          ),
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

    // 축소 상태와 확장 상태에 따라 다른 패딩과 높이 적용
    final verticalPadding = state.isCardViewExpanded ? 8.0 : 4.0;

    return ListView.builder(
      itemCount: markersList.length,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      physics: const BouncingScrollPhysics(), // 부드러운 스크롤 효과
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
        // 이 부분이 수정된 부분: 고정 너비 대신 제약조건 사용
        constraints: BoxConstraints(
          // 최소 너비는 설정하되, 최대 너비는 텍스트 길이에 따라 유연하게 조정
          minWidth: state.isCardViewExpanded ? 120 : 80,
          maxWidth: state.isCardViewExpanded ? 220 : 180,
        ),

        // 기존 코드: width: state.isCardViewExpanded ? 160 : 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColorStyles.primary60 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColorStyles.primary100 : AppColorStyles.gray40,
          ),
        ),
        child:
            state.isCardViewExpanded
                ? _buildExpandedCard(marker)
                : _buildCollapsedCard(marker),
      ),
    );
  }

  // 카드가 접혀있을 때의 UI (간단한 정보만 표시)
  Widget _buildCollapsedCard(MapMarker marker) {
    // 축소된 상태에서는 고정된 영역에 맞추기 위해 Row 레이아웃 사용
    return Row(
      children: [
        // 이미지 영역 (작은 원형으로 표시)
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorStyles.gray40,
          ),
          child: Center(
            child:
                marker.imageUrl.isEmpty
                    ? Icon(
                      marker.type == MarkerType.user
                          ? Icons.person
                          : Icons.group,
                      size: 20,
                      color: AppColorStyles.gray80,
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        marker.imageUrl,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            marker.type == MarkerType.user
                                ? Icons.person
                                : Icons.group,
                            size: 20,
                            color: AppColorStyles.gray80,
                          );
                        },
                      ),
                    ),
          ),
        ),

        // 정보 영역 (제목만 표시)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              marker.title,
              style: AppTextStyles.subtitle1Bold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // 카드가 확장되었을 때의 UI (전체 정보 표시)
  Widget _buildExpandedCard(MapMarker marker) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역 - 비율을 조정하여 높이를 줄임
          Container(
            height: 80, // 이미지 높이 감소
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: AppColorStyles.gray40,
            ),
            child: Center(
              child:
                  marker.imageUrl.isEmpty
                      ? Icon(
                        marker.type == MarkerType.user
                            ? Icons.person
                            : Icons.group,
                        size: 30, // 아이콘 크기 감소
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
                              size: 30,
                              color: AppColorStyles.gray80,
                            );
                          },
                        ),
                      ),
            ),
          ),

          // 정보 영역 - 패딩 축소 및 간격 줄이기
          Padding(
            padding: const EdgeInsets.all(6.0), // 패딩 축소
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 최소 크기만 사용
              children: [
                Text(
                  marker.title,
                  style: AppTextStyles.subtitle1Bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // 간격 축소
                Text(
                  marker.description,
                  style: AppTextStyles.body2Regular,
                  maxLines: 1, // 설명 줄 수 제한
                  overflow: TextOverflow.ellipsis,
                ),

                if (marker.type == MarkerType.group)
                  Padding(
                    padding: const EdgeInsets.only(top: 4), // 간격 축소
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 12, // 아이콘 크기 축소
                          color: AppColorStyles.primary100,
                        ),
                        const SizedBox(width: 2), // 간격 축소
                        Text(
                          '${marker.memberCount}명/${marker.limitMemberCount}명',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColorStyles.primary100,
                            fontSize: 10, // 폰트 크기 축소
                          ),
                        ),
                      ],
                    ),
                  ),

                // 버튼 영역 - 높이 축소
                Padding(
                  padding: const EdgeInsets.only(top: 6), // 상단 패딩 축소
                  child: SizedBox(
                    width: double.infinity,
                    height: 28, // 버튼 높이 고정
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ), // 패딩 제거
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // 더 작은 반경
                        ),
                      ),
                      child: Text(
                        marker.type == MarkerType.user ? '프로필 보기' : '그룹 보기',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white,
                          fontSize: 10, // 폰트 크기 축소
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
