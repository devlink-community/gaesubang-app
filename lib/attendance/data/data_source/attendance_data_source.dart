abstract interface class AttendanceDataSource {
  Future<List<Map<String, dynamic>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required DateTime startDate, // 해당 월의 시작일 (ex. 2025-05-01)
    required DateTime endDate,   // 해당 월의 말일 (ex. 2025-05-31)
  });
}
