import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repository/attendance_repository.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import '../data_source/attendance_data_source.dart';
import '../data_source/mock_attendance_data_source_impl.dart';
import '../repository/attendance_repository_impl.dart';


part 'attendance_di.g.dart';

// DataSource 프로바이더
@riverpod
AttendanceDataSource attendanceDataSource(AttendanceDataSourceRef ref) {
  return MockAttendanceDataSourceImpl();
}

// Repository 프로바이더
@riverpod
AttendanceRepository attendanceRepository(AttendanceRepositoryRef ref) {
  return AttendanceRepositoryImpl(ref.watch(attendanceDataSourceProvider));
}

// UseCase 프로바이더들
@riverpod
GetAttendancesByMonthUseCase getAttendancesByMonthUseCase(GetAttendancesByMonthUseCaseRef ref) {
  return GetAttendancesByMonthUseCase(ref.watch(attendanceRepositoryProvider));
}
