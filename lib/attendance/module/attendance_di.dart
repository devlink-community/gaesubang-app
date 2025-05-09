import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/data_source/attendance_data_source.dart';
import '../data/data_source/mock_attendance_data_source.dart';
import '../data/repository/attendance_repository_impl.dart';
import '../domain/model/group.dart';
import '../domain/model/member.dart';
import '../domain/repository/attendance_repository.dart';
import '../domain/usecase/get_attendance_by_month_use_case.dart';
import '../presentation/attendance/attendance_screen_root.dart';

part 'attendance_di.g.dart';

// Repository
@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource);
}

// DataSource
@riverpod
AttendanceDataSource attendanceDataSource(Ref ref) {
  return MockAttendanceDataSource();
}

// UseCase
@riverpod
GetAttendancesByMonthUseCase getAttendancesByMonthUseCase(Ref ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return GetAttendancesByMonthUseCase(repository);
}

// Router
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ...attendanceRoutes,
    ],
  );
}

// 모듈 라우트 정의
final attendanceRoutes = [
  GoRoute(
    path: '/attendance/:groupId',
    builder: (context, state) {
      final groupId = state.pathParameters['groupId'] ?? '';

      // 참고: 실제 앱에서는 여기서 그룹 정보를 불러오는 로직이 필요할 수 있습니다.
      // 간단한 예제를 위해 빈 그룹 객체를 생성합니다.
      final mockGroup = Group(
        id: groupId,
        name: 'Mock Group',
        description: 'Mock Group Description',
        members: [],
        hashTags: [],
        limitMemberCount: 10,
        owner: Member(
          id: 'owner1',
          email: 'owner@example.com',
          nickname: 'Owner',
          uid: 'owner-uid',
        ),
      );

      return AttendanceScreenRoot(group: mockGroup);
    },
  ),
];