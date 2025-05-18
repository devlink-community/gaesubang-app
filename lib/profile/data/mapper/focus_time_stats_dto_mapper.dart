import '../../domain/model/focus_time_stats.dart';
import '../dto/focus_time_stats_dto_old.dart';

extension FocusTimeStatsDtoMapper on FocusTimeStatsDto {
  FocusTimeStats toModel() => FocusTimeStats(
    totalMinutes: totalMinutes ?? 0,
    weeklyMinutes: weeklyMinutes ?? {},
  );
}
