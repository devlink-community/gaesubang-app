import 'dart:io';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../styles/app_color_styles.dart';
import '../styles/app_text_styles.dart';

// lib/core/component/navigation_bar.dart
// 기존 코드 유지하고 수정이 필요한 부분만 변경

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

  // 메뉴가 열려있을 때 바깥쪽 탭을 감지하기 위한 OverlayEntry
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
        _animationController.reverse();
        _removeOverlay();
      }
    });
  }

  // 오버레이를 표시하여 메뉴 외부 탭을 감지
  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleMenu,
            child: Container(color: Colors.transparent),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 바텀 네비게이션 바
        Container(
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
                      // 중앙 버튼 - 수정된 부분
                      _buildCenterButton(),
                      _buildNavItem(3, LineIcons.userFriends),
                      _buildProfileItem(4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 드롭다운 메뉴 - 수정된 부분
        if (_isExpanded)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onCreatePost != null)
                    _buildMenuItem(
                      icon: Icons.edit_rounded,
                      label: '게시글 작성',
                      onTap: () {
                        _toggleMenu();
                        widget.onCreatePost!();
                      },
                      color: AppColorStyles.secondary01,
                    ),
                  const SizedBox(height: 12),
                  if (widget.onCreateGroup != null)
                    _buildMenuItem(
                      icon: Icons.group_add,
                      label: '그룹 생성',
                      onTap: () {
                        _toggleMenu();
                        widget.onCreateGroup!();
                      },
                      color: AppColorStyles.primary100,
                    ),
                ],
              ),
            ),
          ),
      ],
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

  // 수정된 중앙 버튼
  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColorStyles.primary100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColorStyles.primary100.withOpacity(0.3),
              blurRadius: 6,
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
        width: 26, // 다른 아이콘과 크기 맞춤
        height: 26, // 다른 아이콘과 크기 맞춤
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

  // 수정된 메뉴 아이템
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Function() onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.button2Regular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
