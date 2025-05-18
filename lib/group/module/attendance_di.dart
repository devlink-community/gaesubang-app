import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/attendance_data_source.dart';
import '../data/data_source/mock_attendance_data_source_impl.dart';
import '../data/repository_impl/attendance_repository_impl.dart';
import '../domain/repository/attendance_repository.dart';
import '../domain/usecase/get_attendance_by_month_use_case.dart';
import '../domain/usecase/mock_get_group_detail_use_case.dart';

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

// 출석부 전용 Mock Group Detail UseCase
@riverpod
MockGetGroupDetailUseCase mockGetGroupDetailUseCase(Ref ref) {
  return MockGetGroupDetailUseCase();
}
