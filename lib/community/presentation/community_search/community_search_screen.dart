// lib/community/presentation/community_list_search/community_search_screen.dart
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_action.dart';
import 'package:devlink_mobile_app/community/presentation/community_search/community_search_state.dart';
import 'package:devlink_mobile_app/community/presentation/components/post_list_item.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunitySearchScreen extends StatefulWidget {
  final CommunitySearchState state;
  final void Function(CommunitySearchAction action) onAction;

  const CommunitySearchScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.state.query;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(CommunitySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.query != widget.state.query) {
      _searchController.text = widget.state.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0, // 타이틀과 leading 위젯 사이의 간격 제거
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorStyles.textPrimary),
          onPressed:
              () => widget.onAction(const CommunitySearchAction.onGoBack()),
          padding: const EdgeInsets.only(left: 16.0), // 왼쪽 패딩 추가
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0), // 오른쪽 패딩 추가
          child: _buildSearchField(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child:
            widget.state.query.isNotEmpty
                ? _buildSearchResults()
                : _buildRecentSearches(),
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 40,
      decoration: BoxDecoration(
        color:
            _isFocused ? Colors.white : AppColorStyles.gray40.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused ? AppColorStyles.primary100 : Colors.transparent,
          width: 1.5,
        ),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: AppColorStyles.primary100.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬 명시
        children: [
          // 텍스트 필드 (확장)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                cursorColor: AppColorStyles.primary100,
                decoration: InputDecoration(
                  hintText: '게시글 검색',
                  hintStyle: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray60,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0, // 세로 패딩 제거
                  ),
                  isDense: true, // 텍스트 필드를 더 조밀하게 만듦
                ),
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.textPrimary,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    widget.onAction(CommunitySearchAction.onSearch(value));
                  }
                },
              ),
            ),
          ),

          // 지우기 아이콘 (입력된 텍스트가 있을 때만 표시)
          if (_searchController.text.isNotEmpty)
            AnimatedOpacity(
              opacity: _searchController.text.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColorStyles.gray80,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _searchController.clear();
                  widget.onAction(const CommunitySearchAction.onClearSearch());
                },
              ),
            ),

          // 검색 아이콘
          Container(
            margin: const EdgeInsets.only(right: 8),
            // decoration: BoxDecoration(
            //   color: AppColorStyles.primary100,
            //   shape: BoxShape.circle,
            // ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    widget.onAction(
                      CommunitySearchAction.onSearch(_searchController.text),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.search,
                    color: AppColorStyles.primary100,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (widget.state.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: AppColorStyles.gray60),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: AppTextStyles.body1Regular.copyWith(
                color: AppColorStyles.gray100,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 검색어',
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed:
                    () => widget.onAction(
                      const CommunitySearchAction.onClearAllRecentSearches(),
                    ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColorStyles.gray100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  '전체 삭제',
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 수평 스크롤 최근 검색어 목록
        SizedBox(
          height: 40, // 높이 조정
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.state.recentSearches.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final query = widget.state.recentSearches[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      () => widget.onAction(
                        CommunitySearchAction.onSearch(query),
                      ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColorStyles.gray40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          query,
                          style: AppTextStyles.body1Regular.copyWith(
                            color: AppColorStyles.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColorStyles.gray40,
                            shape: BoxShape.circle,
                          ),
                          child: InkResponse(
                            onTap:
                                () => widget.onAction(
                                  CommunitySearchAction.onRemoveRecentSearch(
                                    query,
                                  ),
                                ),
                            radius: 12,
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: AppColorStyles.gray80,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 나머지 공간 채우는 빈 영역
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchResults = widget.state.searchResults;

    switch (searchResults) {
      case AsyncLoading():
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColorStyles.primary100,
            ),
          ),
        );

      case AsyncError(:final error):
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColorStyles.error,
              ),
              const SizedBox(height: 16),
              Text(
                '검색 중 오류가 발생했습니다',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle1Bold.copyWith(
                  color: AppColorStyles.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.gray100,
                ),
              ),
            ],
          ),
        );

      case AsyncData(:final value):
        if (value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColorStyles.gray60,
                ),
                const SizedBox(height: 16),
                Text(
                  '"${widget.state.query}"에 대한\n검색 결과가 없습니다',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: AppColorStyles.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '다른 검색어로 시도해 보세요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray100,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: value.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final post = value[index];
            return PostListItem(
              post: post,
              onTap:
                  () =>
                      widget.onAction(CommunitySearchAction.onTapPost(post.id)),
            );
          },
        );
    }

    // Default return statement to handle unexpected cases
    return const SizedBox.shrink();
  }
}
