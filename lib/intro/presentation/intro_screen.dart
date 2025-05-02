import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../auth/domain/model/member.dart';
import '../domain/model/focus_time_stats.dart';
import 'component/focus_stats_chart.dart';
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
          // 프로필 부분
          state.userProfile.when(
            data: (member) => _buildProfile(member),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('프로필 정보를 불러올 수 없습니다')),
          ),

          const Divider(),

          // 통계 차트 부분 (남은 공간 채우기)
          Expanded(
            child: state.focusStats.when(
              data: (stats) => FocusStatsChart(stats: stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('통계 정보를 불러올 수 없습니다')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(Member member) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(member.image)),
      title: Text(member.nickname),
      subtitle: Text(member.email),
    );
  }
}
