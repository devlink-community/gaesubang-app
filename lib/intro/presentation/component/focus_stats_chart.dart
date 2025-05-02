import 'package:flutter/material.dart';
import '../../domain/model/focus_time_stats.dart';

class FocusStatsChart extends StatelessWidget {
  final FocusTimeStats stats;

  const FocusStatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 총 집중 시간
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '총 집중 시간: ${stats.totalMinutes}분',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // 요일별 집중 시간
        Expanded(
          child: ListView.builder(
            itemCount: stats.weeklyMinutes.length,
            itemBuilder: (context, index) {
              final entry = stats.weeklyMinutes.entries.elementAt(index);
              return ListTile(
                title: Text(entry.key),
                trailing: Text('${entry.value}분'),
              );
            },
          ),
        ),
      ],
    );
  }
}
