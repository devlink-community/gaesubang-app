abstract interface class AttendanceDataSource {
  Future<List<Map<String,dynamic>>> fetchTimersByGroupAndDate(
    String groupId,
    DateTime date,
  );
}
