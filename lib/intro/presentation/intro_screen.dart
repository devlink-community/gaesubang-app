import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/domain/model/member.dart';
import 'component/focus_stats_chart.dart';
import 'component/user_intro.dart';
import 'intro_action.dart';
import 'intro_state.dart';

class IntroScreen extends StatelessWidget {
  final IntroState state;
  final Future<void> Function(IntroAction) onAction;

  const IntroScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => onAction(const RefreshIntro()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onAction(const OpenSettings()),
          ),
        ],
      ),
      body: Column(
        children: [
          state.userProfile.when(
            data: (Member member) => ProfileInfo(member: member),
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('프로필 정보를 불러올 수 없습니다')),
                ),
          ),

          // 구분선
          const Divider(height: 1),

          // ② 통계 차트 영역
          Padding(
            padding: EdgeInsets.all(30),
            child: Expanded(
              child: state.focusStats.when(
                data: (stats) => FocusStatsChart(stats: stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) => const Center(child: Text('통계 정보를 불러올 수 없습니다')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
