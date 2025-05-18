abstract interface class AttendanceDataSource {
  Future<List<Map<String, dynamic>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // 추가: 타이머 활동을 출석부에 반영
  Future<void> recordTimerAttendance({
    required String groupId,
    required String memberId,
    required DateTime date,
    required int timeInMinutes,
  });
}