import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

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
      // 루트 경로 추가 - 홈 화면 또는 리다이렉트
      GoRoute(
        path: '/',
        // 루트 경로에서 바로 출석부 화면으로 리다이렉트
        redirect: (_, __) => '/attendance/group1',
      ),
      ...attendanceRoutes,
    ],
  );
}

// 모의 그룹 생성 함수
Group _createMockGroup(String groupId) {
  return Group(
    id: groupId,
    name: 'Mock Group',
    description: 'Mock Group Description',
    members: [
      Member(
        id: 'user1',
        email: 'user1@example.com',
        nickname: 'User One',
        uid: 'uid1',
      ),
      Member(
        id: 'user2',
        email: 'user2@example.com',
        nickname: 'User Two',
        uid: 'uid2',
      ),
      Member(
        id: 'user3',
        email: 'user3@example.com',
        nickname: 'User Three',
        uid: 'uid3',
      ),
    ],
    hashTags: ['study', 'programming'],
    limitMemberCount: 10,
    owner: Member(
      id: 'owner1',
      email: 'owner@example.com',
      nickname: 'Owner',
      uid: 'owner-uid',
    ),
  );
}

// 모듈 라우트 정의
final attendanceRoutes = [
  GoRoute(
    path: '/attendance/:groupId',
    builder: (context, state) {
      final groupId = state.pathParameters['groupId'] ?? 'group1';
      // 모의 그룹 객체 생성 (실제 앱에서는 데이터베이스에서 가져와야 함)
      final mockGroup = _createMockGroup(groupId);
      return AttendanceScreenRoot(group: mockGroup);
    },
  ),
];