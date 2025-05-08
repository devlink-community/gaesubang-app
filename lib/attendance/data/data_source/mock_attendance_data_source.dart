import 'dart:async';

import 'package:intl/intl.dart';

import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  final List<Map<String, dynamic>> _mockData = [
    {
      'memberId': 'user1',
      'date': '2025-05-01',
      'time': 30,
    },
    {
      'memberId': 'user1',
      'date': '2025-05-08',
      'time': 250,
    },
    {
      'memberId': 'user2',
      'date': '2025-05-08',
      'time': 130,
    },
    {
      'memberId': 'user3',
      'date': '2025-05-09',
      'time': 60,
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final startKey = DateFormat('yyyy-MM-dd').format(startDate);
    final endKey = DateFormat('yyyy-MM-dd').format(endDate);

    return _mockData.where((e) {
      final memberOk = memberIds.contains(e['memberId']);
      final date = e['date'] as String;
      return memberOk && date.compareTo(startKey) >= 0 && date.compareTo(endKey) <= 0;
    }).toList();
  }
}
