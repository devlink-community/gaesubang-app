
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/attendance_data_source.dart';
import '../data/data_source/mock_attendance_data_source.dart';
import '../data/repository/attendance_repository_impl.dart';
import '../domain/model/member.dart';
import '../domain/repository/attendance_repository.dart';
import '../domain/usecase/get_attendance_by_group_use_case.dart';
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
GetAttendanceByDateUseCase getAttendanceByDateUseCase(Ref ref) =>
    GetAttendanceByDateUseCase(ref.watch(attendanceRepositoryProvider));

@riverpod
List<Member> mockMembers(Ref ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider) as MockAttendanceDataSource;
  return dataSource.getMembersByIds(['user1', 'user2', 'user3', 'user4']);
}

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
