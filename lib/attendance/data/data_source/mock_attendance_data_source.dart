import 'dart:async';

import 'package:intl/intl.dart';

import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  final List<Map<String, dynamic>> _mockData = [
    {
      'memberId': 'user1',
      'date': '2025-05-01',
      'time': 30,
      'groupId': 'group1',
    },
    {
      'memberId': 'user1',
      'date': '2025-05-08',
      'time': 250,
      'groupId': 'group1',
    },
    {
      'memberId': 'user2',
      'date': '2025-05-08',
      'time': 130,
      'groupId': 'group1',
    },
    {
      'memberId': 'user3',
      'date': '2025-05-09',
      'time': 60,
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
  // lib/attendance/data/data_source/mock_attendance_data_source.dart
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