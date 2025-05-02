import 'package:devlink_mobile_app/auth/data/data_source/profile_data_source.dart';

class MockProfileDataSource implements ProfileDataSource {
  @override
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': '0', // 동일한 userId
      'imagePath': 'mock/image/path',
      'onAir': true,
    };
  }
}
