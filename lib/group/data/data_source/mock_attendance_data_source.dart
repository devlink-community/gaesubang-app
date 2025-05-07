import 'dart:async';

import '../dto/attendance_dto.dart';
import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAttendancesByMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final mockData = [
      {
        'memberId': 'user1',
        'date': '2024-06-01',
        'time': 45, // 0%
      },
      {
        'memberId': 'user2',
        'date': '2024-06-02',
        'time': 75, // 20%
      },
      {
        'memberId': 'user3',
        'date': '2024-06-03',
        'time': 130, // 50%
      },
      {
        'memberId': 'user4',
        'date': '2024-06-04',
        'time': 250, // 80%
      },
    ];

    return mockData.where((e) => e['memberId'] == memberId).toList();
  }
}
