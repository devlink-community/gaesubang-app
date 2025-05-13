import 'dart:async';
import 'package:intl/intl.dart';

import 'attendance_data_source.dart';

class MockAttendanceDataSourceImpl implements AttendanceDataSource {
  final List<Map<String, dynamic>> _mockData = [
    {
      'memberId': 'user1',
      'date': '2025-05-01',
      'time': 250,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-02',
      'time': 10,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-03',
      'time': 180,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-06',
      'time': 60,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-08',
      'time': 300,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-10',
      'time': 120,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-12',
      'time': 45,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-14',
      'time': 200,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-15',
      'time': 30,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-16',
      'time': 270,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-18',
      'time': 90,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-19',
      'time': 150,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-20',
      'time': 240,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-22',
      'time': 75,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-23',
      'time': 210,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-25',
      'time': 160,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-26',
      'time': 40,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-28',
      'time': 290,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-30',
      'time': 110,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-31',
      'time': 190,
      'groupId': 'group1',
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

    return _mockData.where((e) {
      final memberOk = memberIds.contains(e['memberId']);
      final groupOk = e['groupId'] == groupId;
      final date = e['date'] as String;
      return memberOk && groupOk && date.compareTo(startKey) >= 0 && date.compareTo(endKey) <= 0;
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

    // 기존 데이터에서 해당하는 출석 기록 찾기
    final existingIdx = _mockData.indexWhere((e) =>
    e['memberId'] == memberId &&
        e['date'] == dateString &&
        e['groupId'] == groupId
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

    print('출석 기록: ${_mockData.where((e) => e['date'] == dateString).toList()}');
  }
}