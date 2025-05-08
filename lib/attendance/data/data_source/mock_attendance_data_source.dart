import 'dart:async';

import 'package:intl/intl.dart';

import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  final _mockData = [
    {
      'memberId': 'user1',
      'date': '2025-06-01',
      'time': 45, // 0%
    },
    {
      'memberId': 'user2',
      'date': '2025-06-02',
      'time': 75, // 20%
    },
    {
      'memberId': 'user3',
      'date': '2025-06-03',
      'time': 130, // 50%
    },
    {
      'memberId': 'user4',
      'date': '2025-06-04',
      'time': 250, // 80%
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByDate({
    required List<String> memberIds,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // '20xx-xx-xx'
    // final dateKey =
    //     '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // print('dateKey: $dateKey');
    // print('필터 대상 groupId: $groupId');
    // print('전체 mockData:');
    // for (final e in mockData) {
    //   print('groupId: ${e['groupId']}, date: ${e['date']}');
    // }
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    return _mockData
        .where((e) => memberIds.contains(e['memberId']) && e['date'] == dateKey)
        .toList();
  }
}
