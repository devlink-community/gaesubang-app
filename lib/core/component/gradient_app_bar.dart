import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class GradientAppBar extends StatelessWidget {
  /// 확장된 앱바의 높이
  final double expandedHeight;

  /// 기본 타이틀 (접힌 상태에서 표시)
  final String? title;

  /// 접힌 상태에서 타이틀을 표시할지 여부
  final bool showTitleWhenCollapsed;

  /// 앱바 최상단에 표시할 작은 텍스트 (확장 상태)
  final String topText;

  /// 앱바 중앙에 표시할 큰 텍스트 (확장 상태)
  final String mainText;

  /// 오른쪽에 표시할 액션 버튼들
  final List<Widget>? actions;

  /// 앱바가 스크롤에 따라 고정될지 여부
  final bool pinned;

  /// 앱바가 위로 스크롤되면 떠 있을지 여부
  final bool floating;

  /// 배경 그라데이션 색상들
  final List<Color>? gradientColors;

  /// 배경에 보여질 장식용 요소
  final List<Widget>? decorationElements;

  const GradientAppBar({
    super.key,
    this.expandedHeight = 120,
    this.title,
    this.showTitleWhenCollapsed = true,
    required this.topText,
    required this.mainText,
    this.actions,
    this.pinned = true,
    this.floating = false,
    this.gradientColors,
    this.decorationElements,
  });

  @override
  Widget build(BuildContext context) {
    // 기본 그라데이션 색상
    final colors =
        gradientColors ??
        [
          AppColorStyles.primary100.withOpacity(0.2),
          AppColorStyles.primary100.withOpacity(0.05),
          Colors.white,
        ];

    // 기본 장식 요소
    final decorations =
        decorationElements ??
        [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColorStyles.primary100.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ];

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.white,
      actions: actions,
      // title이 null이거나 showTitleWhenCollapsed가 false인 경우 툴바 높이 0으로 설정
      toolbarHeight:
          (title == null || !showTitleWhenCollapsed) ? 0 : kToolbarHeight,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 배경 장식 요소
              ...decorations,

              // 콘텐츠 - 오버플로우 방지를 위해 SingleChildScrollView로 감싸기
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 사용 가능한 높이 계산
                      final availableHeight = constraints.maxHeight;
                      final minPadding = 16.0;
                      final maxPadding = 24.0;

                      // 높이에 따라 적응적 패딩 계산
                      final topPadding =
                          availableHeight > 100 ? maxPadding : minPadding;
                      final bottomPadding =
                          availableHeight > 80 ? maxPadding : minPadding;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          maxPadding,
                          topPadding,
                          maxPadding,
                          bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(), // 유연한 공간 확보
                            // 텍스트 컨테이너 - 최소 높이 보장
                            Flexible(
                              flex: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    topText,
                                    style: AppTextStyles.body1Regular.copyWith(
                                      color: AppColorStyles.gray100,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mainText,
                                    style: AppTextStyles.heading6Bold.copyWith(
                                      fontSize: 20,
                                      color: AppColorStyles.textPrimary,
                                    ),
                                    maxLines: 2, // 2줄까지 허용
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 앱바가 작아졌을 때 타이틀 (조건부 표시)
      title:
          (title != null && showTitleWhenCollapsed)
              ? Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColorStyles.primary100,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  title!,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: AppColorStyles.textPrimary,
                  ),
                ),
              )
              : null,
      centerTitle: false,
      titleSpacing: 24,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 1,
          color: AppColorStyles.gray40.withOpacity(0.2),
        ),
      ),
    );
  }
}
