abstract interface class AttendanceDataSource {
  Future<List<Map<String, dynamic>>> fetchAttendancesByGroup({
    required String groupId,
  });
}
