import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repository/attendance_repository.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import '../../presentation/attendance/attendance_screen_root.dart';
import '../data_source/attendance_data_source.dart';
import '../data_source/mock_attendance_data_source_impl.dart';
import '../repository/attendance_repository_impl.dart';

part 'attendance_di.g.dart';

// DataSource 프로바이더
@riverpod
AttendanceDataSource attendanceDataSource(Ref ref) {
  return MockAttendanceDataSourceImpl();
}

// Repository 프로바이더
@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource);
}

// UseCase 프로바이더들
@riverpod
GetAttendancesByMonthUseCase getAttendancesByMonthUseCase(Ref ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return GetAttendancesByMonthUseCase(repository);
}

final routerProvider = Provider<GoRouter>((ref) {
  // 테스트용 기본 그룹 가져오기
  final defaultGroup = MockGroupDataSourceImpl.getDefaultGroup();

  return GoRouter(
    // 앱 시작 시 바로 출석부 화면으로 이동
    initialLocation: '/attendance',
    routes: [
      // 출석 화면만 등록 (HomeScreen 없음)
      GoRoute(
        path: '/attendance',
        builder: (context, state) {
          // 항상 기본 그룹 사용
          return AttendanceScreenRoot(group: defaultGroup);
        },
      ),
    ],
  );
});