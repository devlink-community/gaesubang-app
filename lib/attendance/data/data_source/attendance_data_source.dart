abstract interface class AttendanceDataSource {
  Future<List<Map<String, dynamic>>> fetchAttendancesByDate({
    required List<String> memberIds,
    required DateTime date,
  });
}
