import 'package:devlink_mobile_app/core/component/app_image.dart';
import 'package:devlink_mobile_app/core/component/gradient_app_bar.dart';
import 'package:devlink_mobile_app/core/component/list_skeleton.dart';
import 'package:devlink_mobile_app/core/component/search_bar_component.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/component/group_list_item.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_list/group_list_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/model/group.dart';

enum GroupFilter {
  all('전체'),
  joined('참여 중'),
  open('참여 가능');

  final String label;
  const GroupFilter(this.label);
}

class GroupListScreen extends StatefulWidget {
  final GroupListState state;
  final void Function(GroupListAction action) onAction;

  const GroupListScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  GroupFilter _selectedFilter = GroupFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    print(
      'didChangeDependencies 호출됨, 상태: ${widget.state.groupList.runtimeType}',
    );

    // AsyncValue 패턴 매칭으로 올바르게 접근
    switch (widget.state.groupList) {
      case AsyncData(:final value):
        _precacheImages(value);
        break;
      default:
        // 로딩 중이거나 에러 상태면 아무 작업도 하지 않음
        break;
    }
  }

  void _precacheImages(List<Group> groups) {
    // 화면에 표시될 가능성이 높은 첫 10개 그룹만 사전 로드
    final List<String> imageUrls = [];

    for (final group in groups.take(10)) {
      if (group.imageUrl != null && group.imageUrl!.isNotEmpty) {
        imageUrls.add(group.imageUrl!);
      }

      // 방장 이미지도 사전 로드
      if (group.owner.image.isNotEmpty) {
        imageUrls.add(group.owner.image);
      }
    }

    if (imageUrls.isNotEmpty) {
      AppImage.precacheImages(imageUrls, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          _buildSearchBar(),
          // 스티키 헤더로 필터 바 변경
          SliverPersistentHeader(
            delegate: _StickyFilterBarDelegate(
              minHeight: 70,
              maxHeight: 70,
              child: _buildFilterBar(),
            ),
            pinned: true, // 스크롤 시 고정되도록 설정
          ),
          _buildHeadingText(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return GradientAppBar(
      topText: '안녕하세요 👋',
      mainText: '함께 성장할 그룹을 찾아보세요',
      expandedHeight: 120,
    );
  }

  // 트렌디한 검색 바
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SearchBarComponent(
          onTap: () => widget.onAction(const GroupListAction.onTapSearch()),
          hintText: '관심 있는 그룹을 검색해 보세요',
          icon: Icons.search,
        ),
      ),
    );
  }

  // 필터 바 위젯 - 컨테이너만 반환하도록 수정
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white, // 배경색 유지
      padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 10),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColorStyles.gray40.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children:
              GroupFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _applyFilter(filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColorStyles.primary100
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppColorStyles.primary100.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForFilter(filter),
                              size: 16,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColorStyles.gray80,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter.label,
                              style: AppTextStyles.body2Regular.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColorStyles.gray80,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  // 필터 아이콘 선택
  IconData _getIconForFilter(GroupFilter filter) {
    switch (filter) {
      case GroupFilter.all:
        return Icons.grid_view_rounded;
      case GroupFilter.joined:
        return Icons.check_circle_outline;
      case GroupFilter.open:
        return Icons.people_outline;
    }
  }

  // 필터 적용 로직
  void _applyFilter(GroupFilter filter) {
    // 현재는 상태 변경만 수행
    setState(() {
      _selectedFilter = filter;
    });

    // 실제 구현에서는 여기에 API 호출 또는 상태 관리 로직 추가
    // 예: widget.onAction(GroupListAction.filterGroups(filter.name));
  }

  // 섹션 제목 텍스트
  Widget _buildHeadingText() {
    String headingText;
    switch (_selectedFilter) {
      case GroupFilter.all:
        headingText = '모든 그룹';
        break;
      case GroupFilter.joined:
        headingText = '참여 중인 그룹';
        break;
      case GroupFilter.open:
        headingText = '새로 참여 가능한 그룹';
        break;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColorStyles.primary100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  headingText,
                  style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 18),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    '정렬',
                    style: TextStyle(
                      color: AppColorStyles.primary100,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.sort, size: 16, color: AppColorStyles.primary100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메인 콘텐츠 필터링 로직
  List<Group> _getFilteredGroups(List<Group> groups) {
    switch (_selectedFilter) {
      case GroupFilter.all:
        return groups;
      case GroupFilter.joined:
        return groups
            .where(
              (group) =>
                  widget.state.currentMember != null &&
                  group.members.any(
                    (member) => member.id == widget.state.currentMember!.id,
                  ),
            )
            .toList();
      case GroupFilter.open:
        // 참여 가능은 내가 참여하지 않은 그룹 중에서 인원이 여유 있는 그룹
        return groups
            .where(
              (group) =>
                  group.memberCount < group.limitMemberCount &&
                  (widget.state.currentMember == null ||
                      !group.members.any(
                        (member) => member.id == widget.state.currentMember!.id,
                      )),
            )
            .toList();
    }
  }

  // 메인 콘텐츠 영역
  Widget _buildBody() {
    switch (widget.state.groupList) {
      case AsyncLoading():
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // 스켈레톤 UI 추가
                const ListSkeleton(itemCount: 3),

                // 하단 로딩 표시 (선택적)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColorStyles.primary100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '그룹 정보를 불러오는 중...',
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColorStyles.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case AsyncError(:final error):
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text('데이터를 불러오지 못했습니다', style: AppTextStyles.subtitle1Bold),
                const SizedBox(height: 8),
                Text(
                  '잠시 후 다시 시도해 주세요',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      () => widget.onAction(
                        const GroupListAction.onLoadGroupList(),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorStyles.primary100,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('새로고침'),
                ),
              ],
            ),
          ),
        );
      case AsyncData(:final value):
        final filteredGroups = _getFilteredGroups(value);

        if (filteredGroups.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary100.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getEmptyStateIcon(),
                      size: 60,
                      color: AppColorStyles.primary100.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyStateText(),
                    style: AppTextStyles.subtitle1Bold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateSubtext(),
                    style: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.gray100,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _getEmptyStateAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorStyles.primary100,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(_getEmptyStateButtonText()),
                  ),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = filteredGroups[index];
              final isJoined =
                  widget.state.currentMember != null &&
                  group.members.any(
                    (member) => member.id == widget.state.currentMember!.id,
                  );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.transparent,
                  child: GroupListItem(
                    key: ValueKey('group_${group.id}'),
                    group: group,
                    isCurrentMemberJoined: isJoined,
                    onTap:
                        () => widget.onAction(
                          GroupListAction.onTapGroup(group.id),
                        ),
                  ),
                ),
              );
            }, childCount: filteredGroups.length),
          ),
        );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // 빈 상태 아이콘
  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case GroupFilter.all:
        return Icons.grid_view_rounded;
      case GroupFilter.joined:
        return Icons.groups_outlined;
      case GroupFilter.open:
        return Icons.group_add_outlined;
    }
  }

  // 빈 상태 텍스트
  String _getEmptyStateText() {
    switch (_selectedFilter) {
      case GroupFilter.all:
        return '표시할 그룹이 없습니다';
      case GroupFilter.joined:
        return '참여 중인 그룹이 없습니다';
      case GroupFilter.open:
        return '참여 가능한 그룹이 없습니다';
    }
  }

  // 빈 상태 서브텍스트
  String _getEmptyStateSubtext() {
    switch (_selectedFilter) {
      case GroupFilter.all:
        return '지금 새 그룹을 만들어보세요!';
      case GroupFilter.joined:
        return '새로운 그룹에 참여해보세요!';
      case GroupFilter.open:
        return '새로운 그룹을 직접 만들어보세요!';
    }
  }

  // 빈 상태 버튼 텍스트
  String _getEmptyStateButtonText() {
    switch (_selectedFilter) {
      case GroupFilter.all:
      case GroupFilter.open:
        return '그룹 만들기';
      case GroupFilter.joined:
        return '그룹 찾아보기';
    }
  }

  // 빈 상태 액션
  VoidCallback _getEmptyStateAction() {
    switch (_selectedFilter) {
      case GroupFilter.all:
      case GroupFilter.open:
        return () => widget.onAction(const GroupListAction.onTapCreateGroup());
      case GroupFilter.joined:
        return () => setState(() => _selectedFilter = GroupFilter.all);
    }
  }
}

// 스티키 헤더 delegate 클래스
class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFilterBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 스크롤에 따라 배경에 그림자 효과를 추가하여 구분감 향상
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow:
            overlapsContent
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyFilterBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// 이미지 로딩 실패 시 플레이스홀더 위젯
Widget placeholderImageOnError(dynamic error, StackTrace? stackTrace) {
  return Container(
    color: AppColorStyles.gray40,
    child: Center(
      child: Icon(
        Icons.person_outline,
        color: AppColorStyles.gray100,
        size: 20,
      ),
    ),
  );
}
