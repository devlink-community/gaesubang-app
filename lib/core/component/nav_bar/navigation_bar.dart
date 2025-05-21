import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
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
      print(
        'AppBottomNavigationBar 리빌드: profileImageUrl=${widget.profileImageUrl}',
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
    // 이미지 URL 없는 경우 기본 아이콘
    if (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty) {
      return CircleAvatar(
        radius: 11,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
      );
    }

    // 로컬 이미지 경로인 경우
    if (widget.profileImageUrl!.startsWith('/')) {
      return CircleAvatar(
        radius: 11,
        backgroundImage: FileImage(File(widget.profileImageUrl!)),
        backgroundColor: Colors.grey.shade200,
      );
    }

    // 네트워크 이미지인 경우
    return CircleAvatar(
      radius: 11,
      backgroundImage: NetworkImage(widget.profileImageUrl!),
      backgroundColor: Colors.grey.shade200,
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
