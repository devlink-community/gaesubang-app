import 'dart:io';
import 'dart:math';

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

  // 랜덤 색상을 위한 리스트
  final List<Color> _skillColors = [
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.lime,
  ];

  final Random _random = Random();

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

  // 스킬 문자열을 파싱하는 메서드
  List<Map<String, dynamic>> _parseSkills(String skillsString) {
    if (skillsString.isEmpty) {
      return [];
    }

    // 쉼표로 분리하고 각 스킬에 랜덤 색상 할당
    return skillsString
        .split(',')
        .map((skill) {
          final trimmedSkill = skill.trim();
          if (trimmedSkill.isEmpty) {
            return null;
          }

          // 랜덤 색상 할당
          final color = _skillColors[_random.nextInt(_skillColors.length)];

          return {'name': trimmedSkill, 'color': color};
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // 컴팩트 모드에 따라 크기 조정
    final double imageSize = widget.compact ? 60.0 : 72.0;

    // 소개글이 있는지 확인
    final bool hasDescription = widget.member.description.isNotEmpty;
    final bool isLongDescription =
        widget.member.description.length > 40 ||
        widget.member.description.contains('\n');

    // 샘플 스킬을 쉼표로 분리된 문자열로부터 파싱
    // 실제로는 Member 모델에서 skills 필드 사용
    final String sampleSkillsString =
        widget.member.skills ??
        "Flutter, Dart, Firebase, UI/UX, React Native, GraphQL, Node.js";
    final List<Map<String, dynamic>> skills = _parseSkills(sampleSkillsString);

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
              padding: const EdgeInsets.all(2),
              child: _buildProfileImage(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 이름과 스트릭
        Text(
          widget.member.nickname,
          style: AppTextStyles.heading6Bold.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColorStyles.primary100, AppColorStyles.primary80],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColorStyles.primary100.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.member.streakDays} Day Streak',
                style: AppTextStyles.body2Regular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 직무 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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

              // 직무 내용 (예시)
              Text(
                widget.member.position ?? '개발자',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 소개글 카드
        if (hasDescription)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 소개글 헤더
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColorStyles.primary100,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '소개',
                      style: AppTextStyles.subtitle1Bold.copyWith(
                        fontSize: 16,
                        color: AppColorStyles.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isLongDescription)
                      GestureDetector(
                        onTap: _toggleExpanded,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorStyles.gray40.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded ? '접기' : '더보기',
                                style: AppTextStyles.captionRegular.copyWith(
                                  color: AppColorStyles.textPrimary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 2),
                              RotationTransition(
                                turns: _rotateAnimation,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 12,
                                  color: AppColorStyles.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // 소개글 내용
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Text(
                    widget.member.description,
                    style: AppTextStyles.body1Regular.copyWith(
                      color: AppColorStyles.textPrimary,
                      height: 1.5,
                    ),
                    maxLines: _isExpanded ? null : 1,
                    overflow:
                        _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 스킬 카드
        if (skills.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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

                // 스킬 태그 리스트 - 쉼표로 분리된 스킬을 각각 버튼으로 표시
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: skill['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skill['color'].withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            skill['name'],
                            style: AppTextStyles.body2Regular.copyWith(
                              color: skill['color'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
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
