import 'dart:async';

import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  final mockData = [
    {
      'groupId': 'group1',
      'memberId': 'user1',
      'date': '2025-06-01',
      'time': 45, // 0%
    },
    {
      'groupId': 'group1',
      'memberId': 'user2',
      'date': '2025-06-02',
      'time': 75, // 20%
    },
    {
      'groupId': 'group1',
      'memberId': 'user3',
      'date': '2025-06-03',
      'time': 130, // 50%
    },
    {
      'groupId': 'group1',
      'memberId': 'user4',
      'date': '2025-06-04',
      'time': 250, // 80%
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByGroup({
    required String groupId,
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

    return mockData.where((e) => e['groupId'] == groupId).toList();
  }
}
