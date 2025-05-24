import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class AppBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl;
  final Function()? onCreatePost;
  final Function()? onCreateGroup;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl,
    this.onCreatePost,
    this.onCreateGroup,
  });

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  // 오버레이 엔트리
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _showOverlay();
      } else {
        _animationController.reverse().whenComplete(() {
          if (mounted) _removeOverlay();
        });
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleMenu,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3), // 반투명 배경 추가
                child: Stack(
                  children: [
                    // 드롭다운 메뉴
                    Positioned(
                      bottom: 90, // 바텀 네비게이션 바 위에 위치
                      left: 0,
                      right: 0,
                      child: Center(child: _buildDropdownMenu()),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdownMenu() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)), // 아래에서 위로 슬라이드
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onCreatePost != null)
                    _buildMenuItem(
                      icon: LineIcons.pen,
                      label: '게시글 작성',
                      onTap: () {
                        _toggleMenu();
                        widget.onCreatePost!();
                      },
                    ),
                  if (widget.onCreatePost != null &&
                      widget.onCreateGroup != null)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  if (widget.onCreateGroup != null)
                    _buildMenuItem(
                      icon: LineIcons.users,
                      label: '그룹 생성',
                      onTap: () {
                        _toggleMenu();
                        widget.onCreateGroup!();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      AppLogger.debug(
        'AppBottomNavigationBar 리빌드: profileImageUrl=${widget.profileImageUrl}',
        tag: 'NavigationBar',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 구분선
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey.withAlpha(20),
          ),
          // 내비게이션 바
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, LineIcons.paw),
                  _buildNavItem(1, LineIcons.comment),
                  // 중앙 버튼
                  _buildCenterButton(),
                  _buildNavItem(3, LineIcons.userFriends),
                  _buildProfileItem(4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconData) {
    final isSelected = widget.currentIndex == index;
    return InkWell(
      onTap: () => widget.onTap(index),
      child: Icon(
        iconData,
        size: 26,
        color: isSelected ? AppColorStyles.primary100 : Colors.grey,
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColorStyles.primary100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColorStyles.primary100.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              _isExpanded
                  ? const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                    key: ValueKey('close'),
                  )
                  : const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                    key: ValueKey('add'),
                  ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(int index) {
    final isSelected = widget.currentIndex == index;

    return InkWell(
      onTap: () => widget.onTap(index),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColorStyles.primary100 : Colors.transparent,
            width: 2,
          ),
        ),
        child: _buildProfileImage(),
      ),
    );
  }

  Widget _buildProfileImage() {
    // 이미지 URL이 없는 경우 기본 아이콘
    if (widget.profileImageUrl == null ||
        widget.profileImageUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: 11,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
      );
    }

    final String cleanUrl = widget.profileImageUrl!.trim();

    // 로컬 이미지 경로인 경우 (file:// 또는 / 로 시작)
    if (cleanUrl.startsWith('/') && !cleanUrl.startsWith('http')) {
      try {
        return CircleAvatar(
          radius: 11,
          backgroundImage: FileImage(File(cleanUrl)),
          backgroundColor: Colors.grey.shade200,
          onBackgroundImageError: (exception, stackTrace) {
            AppLogger.error(
              '로컬 이미지 로딩 오류: $cleanUrl',
              tag: 'NavigationBar',
              error: exception,
              stackTrace: stackTrace,
            );
          },
          child: null, // backgroundImage가 로드되면 child는 표시되지 않음
        );
      } catch (e) {
        AppLogger.error(
          '로컬 이미지 파일 접근 실패: $cleanUrl',
          tag: 'NavigationBar',
          error: e,
        );
        return CircleAvatar(
          radius: 11,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
        );
      }
    }

    // 네트워크 이미지인 경우
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      try {
        final uri = Uri.parse(cleanUrl);
        if (uri.host.isEmpty) {
          AppLogger.warning(
            '잘못된 네트워크 이미지 URL: $cleanUrl',
            tag: 'NavigationBar',
          );
          return CircleAvatar(
            radius: 11,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
          );
        }

        return CircleAvatar(
          radius: 11,
          backgroundColor: Colors.grey.shade200,
          child: ClipOval(
            child: Image.network(
              cleanUrl,
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error(
                  '네트워크 이미지 로딩 오류: $cleanUrl',
                  tag: 'NavigationBar',
                  error: error,
                  stackTrace: stackTrace,
                );
                return Icon(
                  Icons.person,
                  size: 11,
                  color: Colors.grey.shade400,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } catch (e) {
        AppLogger.error(
          '네트워크 이미지 URL 파싱 실패: $cleanUrl',
          tag: 'NavigationBar',
          error: e,
        );
        return CircleAvatar(
          radius: 11,
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
        );
      }
    }

    // 지원하지 않는 형식의 경우
    AppLogger.warning('지원하지 않는 이미지 경로 형식: $cleanUrl', tag: 'NavigationBar');
    return CircleAvatar(
      radius: 11,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
    );
  }

  // 새로운 메뉴 아이템 디자인
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
