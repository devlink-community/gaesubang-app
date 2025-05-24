// lib/group/presentation/group_detail/group_detail_screen.dart
import 'dart:async';

import 'package:devlink_mobile_app/core/component/app_image.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/components/gradient_wave_animation.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/components/member_section_header.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/components/timer_display.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_detail/group_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 🔥 순수 UI: StatelessWidget, state 객체만 받음
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  // 🔥 개선: state 객체로 전달 (Root에서 AsyncValue 처리 완료)
  final GroupDetailState state;
  final void Function(GroupDetailAction action) onAction;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late ScrollController _scrollController;
  bool _isTimerVisible = true;
  bool _isMessageExpanded = false;

  // 🔧 실시간 멤버 타이머 업데이트를 위한 Timer 추가
  Timer? _memberTimerUpdateTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 🔧 멤버 타이머 실시간 업데이트 시작
    _startMemberTimerUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔥 순수 UI: state에서 멤버 데이터 안전하게 추출
    final members = _extractMembersData();
    final List<String> imageUrls = [];

    for (final member in members) {
      if (member.profileUrl != null && member.profileUrl!.isNotEmpty) {
        imageUrls.add(member.profileUrl!);
      }
    }

    // 이미지 사전 캐싱
    if (imageUrls.isNotEmpty) {
      AppImage.precacheImages(imageUrls, context);
    }
  }

  void _onScroll() {
    // 스크롤 위치에 따라 타이머 가시성 상태 업데이트
    const double timerThreshold = 220;
    final isTimerCurrentlyVisible = _scrollController.offset < timerThreshold;

    if (isTimerCurrentlyVisible != _isTimerVisible) {
      setState(() {
        _isTimerVisible = isTimerCurrentlyVisible;
      });
    }
  }

  // 🔧 멤버 타이머 실시간 업데이트 시작
  void _startMemberTimerUpdates() {
    _memberTimerUpdateTimer?.cancel();
    _memberTimerUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        // 활성 멤버가 있는 경우에만 UI 업데이트
        final members = _extractMembersData();
        final hasActiveMembers = members.any((member) => member.isActive);

        if (hasActiveMembers && mounted) {
          setState(() {
            // UI 업데이트를 위한 setState
            // 실제 데이터는 GroupMember의 currentElapsedTimeFormat에서 실시간 계산됨
          });
        }
      },
    );
  }

  // 🔧 멤버 타이머 업데이트 중지
  void _stopMemberTimerUpdates() {
    _memberTimerUpdateTimer?.cancel();
    _memberTimerUpdateTimer = null;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // 🔧 멤버 타이머 업데이트 정리
    _stopMemberTimerUpdates();
    super.dispose();
  }

  // 🔥 순수 UI: state에서 안전하게 그룹 데이터 추출
  Group? _extractGroupData() {
    return switch (widget.state.groupDetailResult) {
      AsyncData(:final value) => value,
      _ => null,
    };
  }

  // 🔥 순수 UI: state에서 안전하게 멤버 데이터 추출
  List<GroupMember> _extractMembersData() {
    return switch (widget.state.groupMembersResult) {
      AsyncData(:final value) => value,
      _ => <GroupMember>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 순수 UI: state에서 데이터 추출
    final group = _extractGroupData();
    final members = _extractMembersData();
    final timerStatus = widget.state.timerStatus;
    final elapsedSeconds = widget.state.elapsedSeconds;

    // 🔥 순수 UI: 그룹 데이터가 없으면 빈 화면 (Root에서 처리되어야 하는 상황)
    if (group == null) {
      return const Scaffold(
        body: Center(child: Text('그룹 정보를 불러올 수 없습니다.')),
      );
    }

    final isRunning = timerStatus == TimerStatus.running;

    // 상태에 따른 배경색 결정
    final Color primaryBgColor = switch (timerStatus) {
      TimerStatus.stop => const Color(0xFF9E9E9E), // 정지 상태 - 회색
      TimerStatus.running => const Color(0xFF8080FF), // 실행 중 - 파란색
      _ => const Color(0xFFCDCDFF), // 일시정지 - 연한 파란색
    };

    final Color secondaryBgColor = switch (timerStatus) {
      TimerStatus.stop => const Color(0xFF8E8E8E), // 정지 상태 - 진한 회색
      TimerStatus.running => const Color(0xFF7070EE), // 실행 중 - 진한 파란색
      _ => const Color(0xFFE6E6FA), // 일시정지 - 연한 보라색
    };

    // 🔥 순수 UI: 멤버 분류 로직
    final activeMembers = members.where((m) => m.isActive).toList();
    final inactiveMembers = members.where((m) => !m.isActive).toList();
    final activeCount = activeMembers.length;
    final totalCount = members.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(primaryBgColor, group.name),
      body: Stack(
        children: [
          // 메인 콘텐츠
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 집중시간 영역 (그라데이션 배경)
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryBgColor, secondaryBgColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 그라데이션 물결 애니메이션 배경
                      if (isRunning)
                        GradientWaveAnimation(
                          primaryColor: primaryBgColor,
                          secondaryColor: secondaryBgColor,
                        ),

                      // 타이머 콘텐츠
                      Column(
                        children: [
                          _buildHeader(activeCount, totalCount),
                          TimerDisplay(
                            elapsedSeconds: elapsedSeconds,
                            timerStatus: timerStatus,
                            onToggle:
                                () => widget.onAction(
                                  const GroupDetailAction.toggleTimer(),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 메시지 영역 (해시태그 포함)
              SliverToBoxAdapter(
                child: _buildMessage(group.description, group.hashTags),
              ),

              // 멤버 섹션 헤더
              SliverToBoxAdapter(
                child: _buildMemberSectionHeader(activeCount, totalCount),
              ),

              // 활성 멤버 섹션
              _buildMemberSection(
                title: '활성 멤버',
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle,
                members: activeMembers,
              ),

              // 휴식 중인 멤버 섹션
              _buildMemberSection(
                title: '휴식 중인 멤버',
                color: Colors.grey,
                icon: Icons.nightlight,
                members: inactiveMembers,
              ),

              // 바닥 여백
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),

          // 플로팅 타이머
          _buildFloatingTimerContainer(elapsedSeconds, timerStatus),
        ],
      ),
    );
  }

  // 🔥 순수 UI: 앱바 위젯
  PreferredSizeWidget _buildAppBar(Color backgroundColor, String title) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.heading6Bold.copyWith(color: Colors.white),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: backgroundColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble, color: Colors.white),
          onPressed:
              () => widget.onAction(const GroupDetailAction.navigateToChat()),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed:
              () =>
                  widget.onAction(const GroupDetailAction.navigateToSettings()),
        ),
      ],
    );
  }

  // 🔥 순수 UI: 멤버 섹션 헤더 위젯
  Widget _buildMemberSectionHeader(int activeCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColorStyles.primary100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '함께 공부 중인 멤버 ($activeCount/$totalCount)',
            style: AppTextStyles.subtitle1Bold.copyWith(
              color: AppColorStyles.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 순수 UI: 플로팅 타이머 컨테이너
  Widget _buildFloatingTimerContainer(
    int elapsedSeconds,
    TimerStatus timerStatus,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: _isTimerVisible ? -80 : 0,
      left: 0,
      right: 0,
      height: 56,
      child: Material(
        elevation: 4,
        color: Colors.transparent,
        child: TimerDisplay(
          elapsedSeconds: elapsedSeconds,
          timerStatus: timerStatus,
          onToggle:
              () => widget.onAction(const GroupDetailAction.toggleTimer()),
          isCompact: true,
        ),
      ),
    );
  }

  // 🔥 순수 UI: 멤버 섹션 (헤더 + 그리드)
  Widget _buildMemberSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<GroupMember> members,
  }) {
    // 🔥 순수 UI: 멤버가 없는 경우 빈 공간 반환
    if (members.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 섹션 헤더
            MemberSectionHeader(title: title, color: color, icon: icon),

            // 멤버 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return GestureDetector(
                  onTap:
                      () => widget.onAction(
                        GroupDetailAction.navigateToUserProfile(member.userId),
                      ),
                  child: _buildMemberItem(member),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 개별 멤버 아이템 - 실시간 시간 표시
  Widget _buildMemberItem(GroupMember member) {
    // 🔧 실시간 시간 계산 로직을 직접 구현
    String getTimeDisplay() {
      int seconds;

      if (member.isActive && member.timerStartTime != null) {
        // 활성 상태이면 현재 시간 기준으로 경과 시간 계산
        final now = DateTime.now();
        seconds =
            now.difference(member.timerStartTime!).inSeconds +
            member.elapsedSeconds;
      } else {
        // 비활성 상태이면 저장된 경과 시간 사용
        seconds = member.elapsedSeconds;
      }

      // 시간 포맷팅
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final remainingSeconds = seconds % 60;

      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 프로필 이미지
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      member.isActive
                          ? AppColorStyles.primary100
                          : AppColorStyles.gray40,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child:
                    member.profileUrl != null && member.profileUrl!.isNotEmpty
                        ? Image.network(
                          member.profileUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.person,
                                size: 30,
                              ),
                        )
                        : const Icon(Icons.person, size: 30),
              ),
            ),

            // 상태 표시
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color:
                      member.isActive
                          ? AppColorStyles.success
                          : AppColorStyles.gray80,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 🔧 타이머 표시 - 직접 계산된 시간 사용
        member.isActive
            ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColorStyles.primary60.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                getTimeDisplay(), // 🔧 직접 계산된 시간 표시
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColorStyles.primary100,
                ),
              ),
            )
            : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '휴식중',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        const SizedBox(height: 4),

        // 이름
        Text(
          member.userName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                member.isActive
                    ? AppColorStyles.primary100
                    : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // 🔥 순수 UI: 상단 정보 영역 (참여자 수, 날짜)
  Widget _buildHeader(int activeCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$activeCount / $totalCount',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap:
                () => widget.onAction(
                  const GroupDetailAction.navigateToAttendance(),
                ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap:
                () => widget.onAction(const GroupDetailAction.navigateToMap()),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 순수 UI: 메시지 영역
  Widget _buildMessage(String description, List<String> hashTags) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorStyles.gray40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 - 아이콘과 타이틀, 토글 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _isMessageExpanded = !_isMessageExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColorStyles.gray100,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '그룹 메시지',
                      style: AppTextStyles.body2Regular.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorStyles.gray100,
                      ),
                    ),
                  ],
                ),
                // 확장/축소 아이콘
                Icon(
                  _isMessageExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: AppColorStyles.gray100,
                ),
              ],
            ),
          ),

          // 메시지 내용 - 확장 시에만 표시
          if (_isMessageExpanded) ...[
            const SizedBox(height: 8),
            Text(
              description.isNotEmpty ? description : '그룹 설명이 없습니다.',
              style: AppTextStyles.body1Regular.copyWith(
                height: 1.4,
                color: AppColorStyles.textPrimary,
              ),
            ),
            if (hashTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              // 해시태그
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    hashTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorStyles.primary60.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColorStyles.primary100,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
