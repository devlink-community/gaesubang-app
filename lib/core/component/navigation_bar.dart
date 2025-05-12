import 'package:flutter/material.dart';

import '../styles/app_color_styles.dart';
import '../styles/app_text_styles.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl; // 프로필 이미지 URL 추가

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl, // 선택적 매개변수로 추가
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            color: Colors.grey.withOpacity(0.2),
          ),
          // 내비게이션 바
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, "홈"),
                  _buildNavItem(1, Icons.chat_bubble_outline, "채팅"),
                  _buildNavItem(2, Icons.people_outline, "커뮤니티"),
                  _buildNavItem(3, Icons.notifications_none, "알림"),
                  _buildProfileItem(4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColorStyles.primary100 : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.captionRegular.copyWith(
              color: isSelected ? AppColorStyles.primary100 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(int index) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? AppColorStyles.primary100 : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage(
                profileImageUrl ??
                    'https://via.placeholder.com/150', // 멤버 이미지 사용, 없으면 기본 이미지
              ),
              backgroundColor: Colors.grey.shade200, // 이미지 로딩 중 보여질 배경색
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "프로필",
            style: AppTextStyles.captionRegular.copyWith(
              color: isSelected ? AppColorStyles.primary100 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
