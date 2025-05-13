import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/domain/model/member.dart';
import '../../../group/domain/model/group.dart';
import '../../domain/repository/attendance_repository.dart';
import '../../domain/usecase/get_attendance_by_month_use_case.dart';
import '../data_source/attendance_data_source.dart';
import '../data_source/mock_attendance_data_source.dart';
import '../repository/attendance_repository_impl.dart';


/// DataSource 계층 Provider
final attendanceDataSourceProvider = Provider<AttendanceDataSource>((ref) {
  return MockAttendanceDataSource();
});

/// Repository 계층 Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource);
});

/// UseCase 계층 Provider
final getAttendancesByMonthUseCaseProvider = Provider<GetAttendancesByMonthUseCase>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return GetAttendancesByMonthUseCase(repository);
});

/// 임시 모의 그룹 Provider (실제 구현에서는 제거 예정)
final mockGroupProvider = Provider<Group>((ref) {
  return Group(
    id: 'mock-group-id',
    name: '테스트 그룹',
    description: '개발 테스트를 위한 임시 그룹입니다.',
    members: [
      const Member(
        id: 'user1',
        email: 'user1@example.com',
        nickname: '사용자1',
        uid: 'uid1',
      ),
      const Member(
        id: 'user2',
        email: 'user2@example.com',
        nickname: '사용자2',
        uid: 'uid2',
      ),
      const Member(
        id: 'user3',
        email: 'user3@example.com',
        nickname: '사용자3',
        uid: 'uid3',
      ),
    ],
    hashTags: '테스트',
    limitMemberCount: 10,
    owner: const Member(
      id: 'owner',
      email: 'owner@example.com',
      nickname: '관리자',
      uid: 'owner-uid',
    ),
  );
});

/// 개발용 기본 그룹 (ProviderScope 문제 해결)
final Group _defaultGroup = Group(
  id: 'default-group-id',
  name: '기본 그룹',
  description: '개발용 기본 그룹입니다.',
  members: [
    const Member(
      id: 'user1',
      email: 'user1@example.com',
      nickname: '사용자1',
      uid: 'uid1',
    ),
    const Member(
      id: 'user2',
      email: 'user2@example.com',
      nickname: '사용자2',
      uid: 'uid2',
    ),
  ],
  hashTags: ['테스트'],
  limitMemberCount: 5,
  owner: const Member(
    id: 'owner',
    email: 'owner@example.com',
    nickname: '관리자',
    uid: 'owner-uid',
  ),
);

/// Route 정의
final attendanceRoutes = [
  GoRoute(
    path: '/attendance',
    builder: (context, state) {
      // 실제 앱에서는 state.extra에서 그룹 받기
      // 개발 테스트를 위해 모의 그룹 사용
      final group = state.extra is Group
          ? state.extra as Group
          : _defaultGroup; // 기본 그룹 사용

      return AttendanceScreenRoot(group: group);
    },
  ),
];

/// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/attendance',
    routes: attendanceRoutes,
  );
});