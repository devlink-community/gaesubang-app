import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/model/member.dart';
import '../../../core/styles/app_text_styles.dart';

class ProfileInfo extends StatefulWidget {
  final Member member;
  final bool compact;

  const ProfileInfo({super.key, required this.member, this.compact = false});

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 컴팩트 모드에 따라 크기 조정
    final double imageSize = widget.compact ? 60.0 : 72.0;

    // 소개글이 있는지 확인
    final bool hasDescription = widget.member.description.isNotEmpty;

    // 직무와 스킬이 있는지 확인
    final bool hasPosition =
        widget.member.position != null && widget.member.position!.isNotEmpty;
    final bool hasSkills =
        widget.member.skills != null && widget.member.skills!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 프로필 이미지 (중앙 정렬)
        Align(
          alignment: Alignment.center,
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColorStyles.primary100.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColorStyles.primary100.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: _buildProfileImage(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 이름
        Text(
          widget.member.nickname,
          style: AppTextStyles.heading6Bold.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // 소개글
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            hasDescription ? widget.member.description : "아직 소개글이 작성되지 않았어요",
            style: AppTextStyles.body2Regular.copyWith(
              color:
                  hasDescription
                      ? AppColorStyles.textPrimary
                      : AppColorStyles.gray80,
              fontWeight: FontWeight.w400,
              fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 24),

        // 직무 정보 - 있을 때만 표시
        if (hasPosition)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 직무 제목
                Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 18,
                      color: AppColorStyles.primary100,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '직무',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        fontSize: 16,
                        color: AppColorStyles.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 직무 내용
                Text(
                  widget.member.position!,
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 스킬 카드 - 있을 때만 표시
        if (hasSkills)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 스킬 헤더
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      size: 18,
                      color: AppColorStyles.primary100,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '스킬',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        fontSize: 16,
                        color: AppColorStyles.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 스킬 태그 리스트
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildSkillTags(widget.member.skills!),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 스킬 태그 생성 함수
  List<Widget> _buildSkillTags(String skills) {
    // 스킬 문자열을 쉼표로 구분하여 리스트로 변환
    final skillList =
        skills
            .split(',')
            .map((skill) => skill.trim())
            .where((skill) => skill.isNotEmpty)
            .toList();

    // 각 스킬에 대한 태그 위젯 생성
    return skillList.map((skill) {
      // 스킬별로 색상 할당 (고정)
      final colorIndex = skill.hashCode % 5;
      final colors =
          [
            {
              'bg': const Color(0xFFE3F2FD),
              'text': const Color(0xFF1976D2),
            }, // 파란색
            {
              'bg': const Color(0xFFF3E5F5),
              'text': const Color(0xFF9C27B0),
            }, // 보라색
            {
              'bg': const Color(0xFFFFF3E0),
              'text': const Color(0xFFFF9800),
            }, // 주황색
            {
              'bg': const Color(0xFFE8F5E9),
              'text': const Color(0xFF43A047),
            }, // 초록색
            {
              'bg': const Color(0xFFFFEBEE),
              'text': const Color(0xFFE53935),
            }, // 빨간색
          ][colorIndex];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors['bg'] as Color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (colors['text'] as Color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          skill,
          style: AppTextStyles.body2Regular.copyWith(
            color: colors['text'] as Color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildProfileImage() {
    if (widget.member.image.isEmpty) {
      return CircleAvatar(
        radius: widget.compact ? 30 : 40,
        backgroundColor: Colors.grey.shade100,
        child: Icon(
          Icons.person,
          size: widget.compact ? 30 : 40,
          color: AppColorStyles.primary60,
        ),
      );
    }

    if (widget.member.image.startsWith('/')) {
      return CircleAvatar(
        radius: widget.compact ? 30 : 40,
        backgroundImage: FileImage(File(widget.member.image)),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('이미지 로딩 오류: $exception');
          return;
        },
      );
    }

    return CircleAvatar(
      radius: widget.compact ? 30 : 40,
      backgroundImage: NetworkImage(widget.member.image),
      backgroundColor: Colors.grey.shade200,
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('이미지 로딩 오류: $exception');
        return;
      },
    );
  }
}
