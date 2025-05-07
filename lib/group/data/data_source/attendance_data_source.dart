abstract interface class AttendanceDataSource {
  Future<List<Map<String,dynamic>>> fetchAttendancesByMember(
    String groupId,
  );
}
