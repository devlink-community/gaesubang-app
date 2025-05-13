// DataSource 프로바이더
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
AttendanceDataSource groupDataSource(Ref ref) => MockAttendanceDataSourceImpl();

// Repository 프로바이더
@riverpod
AttendanceRepository groupRepository(Ref ref) =>
    AttendanceRepositoryImpl(dataSource: ref.watch(DataSourceProvider));

// UseCase 프로바이더들
@riverpod
GetAttendanceListUseCase getAttendanceListUseCase(Ref ref) =>
    GetAttendanceListUseCase(repository: ref.watch(RepositoryProvider));


// ==================== 그룹 타이머 관련 DI ====================

// TimerDataSource 프로바이더
@riverpod
AttendanceDataSource timerDataSource(Ref ref) => MockAttendanceDataSourceImpl();

// AttendanceRepository 프로바이더
@riverpod
AttendanceRepository timerRepository(Ref ref) =>
    AttendanceRepositoryImpl(dataSource: ref.watch(DataSourceProvider));

// Attendance UseCase 프로바이더들
@riverpod
StartAttendanceUseCase startAttendanceUseCase(Ref ref) =>
    StartAttendanceUseCase(repository: ref.watch(RepositoryProvider));

final List<GoRoute> groupRoutes = [
  GoRoute(
    path: '/group',
    builder: (context, state) => const GroupListScreenRoot(),
  ),
]