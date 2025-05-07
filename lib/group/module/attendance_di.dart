
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/attendance_data_source.dart';
import '../data/data_source/mock_attendance_data_source.dart';
import '../data/repository_impl/attendance_repository_impl.dart';
import '../domain/repository/attendance_repository.dart';
import '../domain/usecase/get_group_attendance_use_case.dart';
import '../presentation/attendance/attendance_screen_root.dart';

part 'attendance_di.g.dart';

// ------------------- DI -------------------

@riverpod
AttendanceDataSource attendanceDataSource(Ref ref) =>
    MockAttendanceDataSource();

@riverpod
AttendanceRepository attendanceRepository(Ref ref) =>
    AttendanceRepositoryImpl(ref.watch(attendanceDataSourceProvider));

@riverpod
GetGroupAttendanceUseCase getGroupAttendanceUseCase(Ref ref) =>
    GetGroupAttendanceUseCase(ref.watch(attendanceRepositoryProvider));

// ------------------- Route -------------------

final List<GoRoute> attendanceRoutes = [
  GoRoute(
    path: '/attendance',
    builder: (context, state) => const AttendanceScreenRoot(),
  ),
];

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/attendance',
    routes: [...attendanceRoutes],
  );
}
