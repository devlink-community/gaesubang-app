import 'attendance_data_source.dart';

class MockAttendanceDataSource implements AttendanceDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchTimersByGroupAndDate(
    String groupId,
    DateTime date,
  ) async {
    return [
      {
        'memberId': 'user1',
        'minTime': 15,
        'totalTime': 45, // 0% 출석
      },
      {
        'memberId': 'user2',
        'minTime': 30,
        'totalTime': 75, // 20%
      },
      {
        'memberId': 'user3',
        'minTime': 40,
        'totalTime': 130, // 50%
      },
      {
        'memberId': 'user4',
        'minTime': 60,
        'totalTime': 250, // 80%
      },
    ];
  }
}
