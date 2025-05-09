abstract interface class AttendanceDataSource {
  Future<List<Map<String, dynamic>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required String groupId, // groupId 추가
    required DateTime startDate,
    required DateTime endDate,
  });
}