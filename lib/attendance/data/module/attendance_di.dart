import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../group/domain/model/group.dart';
import '../../domain/repository/attendance_repository.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import '../../presentation/attendance/attendance_screen_root.dart';
import '../data_source/attendance_data_source.dart';
import '../data_source/mock_attendance_data_source.dart';
import '../repository/attendance_repository_impl.dart';


/// ------------------- Provider 정의 -------------------

final attendanceDataSourceProvider = Provider<AttendanceDataSource>((ref) {
  return MockAttendanceDataSource();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource);
});

final getAttendancesByMonthUseCaseProvider =
Provider<GetAttendancesByMonthUseCase>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return GetAttendancesByMonthUseCase(repository);
});

/// ------------------- Route 정의 -------------------

final List<GoRoute> attendanceRoutes = [
  GoRoute(
    path: '/attendance',
    builder: (context, state) {
      final group = state.extra as Group;
      return AttendanceScreenRoot(group: group);
    },
  ),
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/attendance',
    routes: attendanceRoutes,
  );
});
