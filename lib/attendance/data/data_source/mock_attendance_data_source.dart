import 'dart:async';

import 'package:intl/intl.dart';

import '../../domain/model/member.dart';
import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  final _mockData = [
    {
      'memberId': 'user1',
      'groupId': 'group1',
      'date': '2025-05-08',
      'time': 250,
    },
    {
      'memberId': 'user2',
      'groupId': 'group1',
      'date': '2025-05-09',
      'time': 130,
    },
    {
      'memberId': 'user3',
      'groupId': 'group1',
      'date': '2025-05-09',
      'time': 70,
    },
    // 다른 월 데이터도 넣어줘도 됨
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByGroup({
    required String groupId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockData.where((e) => e['groupId'] == groupId).toList();
  }
}
