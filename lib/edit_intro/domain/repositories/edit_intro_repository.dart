import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/auth/domain/model/member.dart';

final editIntroRepositoryProvider = Provider<EditIntroRepository>((ref) {
  return EditIntroRepositoryImpl();
});

abstract class EditIntroRepository {
  Future<Member> getCurrentProfile();
  Future<Member> updateProfile({
    required String nickname,
    String? intro,
  });
  Future<Member> updateProfileImage(XFile image);
}

class EditIntroRepositoryImpl implements EditIntroRepository {
  @override
  Future<Member> getCurrentProfile() async {
    // TODO: API 호출 구현
    throw UnimplementedError();
  }

  @override
  Future<Member> updateProfile({
    required String nickname,
    String? intro,
  }) async {
    // TODO: API 호출 구현
    throw UnimplementedError();
  }

  @override
  Future<Member> updateProfileImage(XFile image) async {
    // TODO: API 호출 구현
    throw UnimplementedError();
  }
}
