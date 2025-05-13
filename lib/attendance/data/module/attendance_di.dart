import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/model/group.dart';
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
  return GoRouter(
    initialLocation: '/',
    routes: [

      // 출석 화면
      GoRoute(
        path: '/attendance',
        builder: (context, state) {
          final group = state.extra as Group;
          return AttendanceScreenRoot(group: group);
        },
      ),

      // 필요한 경우 추가 라우트 설정
    ],
    // 에러 핸들링
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('경로를 찾을 수 없습니다: ${state.uri}'))),
  );
});
