import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:flutter/material.dart';

class GroupLeaveDialog extends StatefulWidget {
  final Group group;
  final bool isOwner; // 방장 여부
  final VoidCallback onConfirmLeave; // 탈퇴 확인
  final VoidCallback onCancel; // 취소

  const GroupLeaveDialog({
    super.key,
    required this.group,
    required this.isOwner,
    required this.onConfirmLeave,
    required this.onCancel,
  });

  @override
  State<GroupLeaveDialog> createState() => _GroupLeaveDialogState();
}

class _GroupLeaveDialogState extends State<GroupLeaveDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 스케일 애니메이션
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // 슬라이드 애니메이션
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 애니메이션 시작
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4), // 다크 오버레이
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  // 글래스모피즘 효과
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 상단 아이콘과 제목
                        _buildHeader(),

                        const SizedBox(height: 24),

                        // 그룹 카드
                        _buildGroupCard(),

                        const SizedBox(height: 24),

                        // 메시지
                        _buildMessage(),

                        // 방장 경고 (조건부)
                        if (widget.isOwner) ...[
                          const SizedBox(height: 20),
                          _buildOwnerWarning(),
                        ],

                        const SizedBox(height: 32),

                        // 액션 버튼들
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 아이콘 원형 배경
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  widget.isOwner
                      ? [
                        AppColorStyles.warning.withValues(alpha: 0.2),
                        AppColorStyles.warning.withValues(alpha: 0.1),
                      ]
                      : [
                        AppColorStyles.error.withValues(alpha: 0.2),
                        AppColorStyles.error.withValues(alpha: 0.1),
                      ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  widget.isOwner
                      ? AppColorStyles.warning.withValues(alpha: 0.3)
                      : AppColorStyles.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            widget.isOwner ? Icons.shield_outlined : Icons.logout_rounded,
            color:
                widget.isOwner ? AppColorStyles.warning : AppColorStyles.error,
            size: 28,
          ),
        ),

        const SizedBox(height: 16),

        // 제목
        Text(
          widget.isOwner ? '그룹 소유자 권한' : '그룹 탈퇴',
          style: AppTextStyles.subtitle1Bold.copyWith(
            color: AppColorStyles.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorStyles.primary100.withValues(alpha: 0.08),
            AppColorStyles.primary100.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorStyles.primary100.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 그룹 이미지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColorStyles.primary100.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  widget.group.imageUrl != null &&
                          widget.group.imageUrl!.isNotEmpty
                      ? Image.network(
                        widget.group.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColorStyles.primary100,
                                  AppColorStyles.primary80,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColorStyles.primary100,
                              AppColorStyles.primary80,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
            ),
          ),

          const SizedBox(width: 16),

          // 그룹 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: AppTextStyles.subtitle1Bold.copyWith(
                    color: AppColorStyles.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 14,
                      color: AppColorStyles.gray100,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.group.memberCount}명 참여 중',
                      style: AppTextStyles.body2Regular.copyWith(
                        color: AppColorStyles.gray100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 뱃지 (소유자 표시)
          if (widget.isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorStyles.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorStyles.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '방장',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColorStyles.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      _getMessage(),
      style: AppTextStyles.body1Regular.copyWith(
        color: AppColorStyles.gray100,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOwnerWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorStyles.warning.withValues(alpha: 0.1),
            AppColorStyles.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorStyles.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColorStyles.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 16,
              color: AppColorStyles.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '소유권 이전 후 탈퇴가 가능합니다',
              style: AppTextStyles.body2Regular.copyWith(
                color: AppColorStyles.warning,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorStyles.gray40,
                width: 1.5,
              ),
            ),
            child: TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                splashFactory: InkRipple.splashFactory,
              ),
              child: Text(
                '취소',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.gray100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 확인/탈퇴 버튼
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient:
                  widget.isOwner
                      ? LinearGradient(
                        colors: [
                          AppColorStyles.gray60,
                          AppColorStyles.gray80,
                        ],
                      )
                      : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorStyles.error,
                          AppColorStyles.error.withValues(alpha: 0.8),
                        ],
                      ),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  widget.isOwner
                      ? null
                      : [
                        BoxShadow(
                          color: AppColorStyles.error.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
            ),
            child: ElevatedButton(
              onPressed: widget.isOwner ? null : widget.onConfirmLeave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                splashFactory: InkRipple.splashFactory,
              ),
              child: Text(
                widget.isOwner ? '탈퇴 불가' : '탈퇴하기',
                style: AppTextStyles.body1Regular.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMessage() {
    if (widget.isOwner) {
      return '그룹 소유자는 바로 탈퇴할 수 없어요.\n다른 멤버에게 소유권을 이전한 후 탈퇴해주세요.';
    } else {
      return '정말로 이 그룹에서 탈퇴하시겠어요?\n\n탈퇴 후에는 다시 참여 신청을 통해\n그룹에 들어올 수 있어요.';
    }
  }
}
