import 'dart:async';

import 'package:intl/intl.dart';

import 'attendance_data_source.dart';

class MockAttendanceDataSourceImpl implements AttendanceDataSource {
  final List<Map<String, dynamic>> _mockData = [
    // user1 출석 데이터
    {
      'memberId': 'user1',
      'date': '2025-05-01',
      'time': 250,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-02',
      'time': 10,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-03',
      'time': 180,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-06',
      'time': 60,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-08',
      'time': 300,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-10',
      'time': 120,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-12',
      'time': 45,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-14',
      'time': 200,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-15',
      'time': 30,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-16',
      'time': 270,
      'groupId': 'group_any',
    },

    // user2 출석 데이터 추가
    {
      'memberId': 'user2',
      'date': '2025-05-02',
      'time': 180,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user2',
      'date': '2025-05-04',
      'time': 90,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user2',
      'date': '2025-05-07',
      'time': 240,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user2',
      'date': '2025-05-09',
      'time': 150,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user2',
      'date': '2025-05-11',
      'time': 220,
      'groupId': 'group_any',
    },

    // user3 출석 데이터 추가
    {
      'memberId': 'user3',
      'date': '2025-05-01',
      'time': 120,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user3',
      'date': '2025-05-05',
      'time': 300,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user3',
      'date': '2025-05-08',
      'time': 80,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user3',
      'date': '2025-05-13',
      'time': 200,
      'groupId': 'group_any',
    },
    {
      'memberId': 'user3',
      'date': '2025-05-17',
      'time': 180,
      'groupId': 'group_any',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // API 호출 시간을 시뮬레이션하기 위한 지연
    await Future.delayed(const Duration(milliseconds: 300));

    final startKey = DateFormat('yyyy-MM-dd').format(startDate);
    final endKey = DateFormat('yyyy-MM-dd').format(endDate);

    // memberIds와 날짜 범위에 맞는 데이터 반환
    return _mockData.where((e) {
      final memberOk = memberIds.contains(e['memberId']);
      final date = e['date'] as String;
      final dateOk =
          date.compareTo(startKey) >= 0 && date.compareTo(endKey) <= 0;
      return memberOk && dateOk;
    }).toList();
  }

  @override
  Future<void> recordTimerAttendance({
    required String groupId,
    required String memberId,
    required DateTime date,
    required int timeInMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    // 기존 기록이 있는지 확인
    final existingIdx = _mockData.indexWhere(
      (e) =>
          e['memberId'] == memberId &&
          e['date'] == dateString &&
          e['groupId'] == groupId,
    );

    if (existingIdx >= 0) {
      // 기존 기록이 있으면 시간 추가
      final currentTime = _mockData[existingIdx]['time'] as int;
      _mockData[existingIdx]['time'] = currentTime + timeInMinutes;
    } else {
      // 없으면 새 기록 추가
      _mockData.add({
        'memberId': memberId,
        'date': dateString,
        'time': timeInMinutes,
        'groupId': groupId,
      });
    }

    print('출석 기록 추가: $dateString, 멤버: $memberId, 시간: $timeInMinutes분');
  }
}
