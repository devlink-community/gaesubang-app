import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/result/result.dart';

abstract interface class ProfileSettingRepository {
  Future<Result<Member>> getCurrentProfile();

  Future<Result<Member>> updateProfile({
    required String nickname,
    String? intro,
    String? position, // position 매개변수 추가
    String? skills, // skills 매개변수 추가
  });

  Future<Result<Member>> updateProfileImage(XFile image);
}
