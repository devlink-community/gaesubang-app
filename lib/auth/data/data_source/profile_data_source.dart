abstract interface class ProfileDataSource {
  Future<Map<String, dynamic>> fetchUserProfile(String userId);
}
