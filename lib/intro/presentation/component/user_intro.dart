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
  late Animation<double> _fadeAnimation;

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
    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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
    // final double iconSize = widget.compact ? 24.0 : 30.0;

    // 소개글이 있는지 확인
    final bool hasDescription = widget.member.description.isNotEmpty;
    final bool isLongDescription =
        widget.member.description.length > 80 ||
        widget.member.description.split('\n').length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 프로필 사진에 애니메이션 효과 추가
            TweenAnimationBuilder(
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
                      AppColorStyles.primary100.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorStyles.primary100.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2), // 테두리 효과를 위한 패딩
                child: _buildProfileImage(),
              ),
            ),
            SizedBox(width: widget.compact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.member.nickname,
                          style:
                              widget.compact
                                  ? AppTextStyles.subtitle1Bold
                                  : AppTextStyles.heading6Bold.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.compact ? 2 : 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColorStyles.primary100,
                              AppColorStyles.primary80,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColorStyles.primary100.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: widget.compact ? 14 : 16,
                            ),
                            SizedBox(width: widget.compact ? 2 : 4),
                            Text(
                              '${widget.member.streakDays} Day',
                              style: (widget.compact
                                      ? AppTextStyles.captionRegular
                                      : AppTextStyles.body2Regular)
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 소개글 영역 (컴팩트 모드가 아니고 소개글이 있는 경우에만)
        if (!widget.compact && hasDescription) ...[
          const SizedBox(height: 16),

          // 소개글 컨테이너
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorStyles.primary100.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorStyles.primary100.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘과 "소개" 텍스트 행
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColorStyles.primary100,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '소개',
                      style: AppTextStyles.subtitle2Regular.copyWith(
                        color: AppColorStyles.primary100,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 소개글 내용 (애니메이션 적용)
                GestureDetector(
                  onTap: isLongDescription ? _toggleExpanded : null,
                  child: AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.member.description,
                            style: AppTextStyles.body1Regular.copyWith(
                              color: AppColorStyles.textPrimary.withValues(
                                alpha: _fadeAnimation.value,
                              ),
                              height: 1.4,
                            ),
                            maxLines: _isExpanded ? null : 2,
                            overflow:
                                _isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                          ),
                          if (isLongDescription) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorStyles.primary100.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isExpanded ? '접기' : '더보기',
                                      style: AppTextStyles.captionRegular
                                          .copyWith(
                                            color: AppColorStyles.primary100,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 2),
                                    RotationTransition(
                                      turns: _rotateAnimation,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: AppColorStyles.primary100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImage() {
    // 이미지 처리 로직은 기존과 동일하되 UI 개선
    if (widget.member.image.isEmpty) {
      return CircleAvatar(
        radius: widget.compact ? 30 : 36,
        backgroundColor: Colors.grey.shade100,
        child: Icon(
          Icons.person,
          size: widget.compact ? 30 : 36,
          color: AppColorStyles.primary60,
        ),
      );
    }

    if (widget.member.image.startsWith('/')) {
      return CircleAvatar(
        radius: widget.compact ? 30 : 36,
        backgroundImage: FileImage(File(widget.member.image)),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('이미지 로딩 오류: $exception');
          return;
        },
      );
    }

    return CircleAvatar(
      radius: widget.compact ? 30 : 36,
      backgroundImage: NetworkImage(widget.member.image),
      backgroundColor: Colors.grey.shade200,
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('이미지 로딩 오류: $exception');
        return;
      },
    );
  }
}
