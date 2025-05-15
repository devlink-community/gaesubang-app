import 'dart:io';

import 'package:flutter/material.dart';

import '../styles/app_color_styles.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
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
                  _buildNavItem(0, 'assets/images/navi1.png'),
                  _buildNavItem(1, 'assets/images/navi2.png'),
                  _buildNavItem(2, 'assets/images/navi3.png'),
                  _buildNavItem(3, 'assets/images/navi4.png'),
                  _buildProfileItem(4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String imagePath) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Image.asset(
        imagePath,
        width: 26,
        height: 26,
        color: isSelected ? AppColorStyles.primary100 : Colors.grey,
      ),
    );
  }

  Widget _buildProfileItem(int index) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
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
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return CircleAvatar(
        radius: 11,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 11, color: Colors.grey.shade400),
      );
    }

    // 로컬 이미지 경로인 경우
    if (profileImageUrl!.startsWith('/')) {
      return CircleAvatar(
        radius: 11,
        backgroundImage: FileImage(File(profileImageUrl!)),
        backgroundColor: Colors.grey.shade200,
      );
    }

    // 네트워크 이미지인 경우
    return CircleAvatar(
      radius: 11,
      backgroundImage: NetworkImage(profileImageUrl!),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
