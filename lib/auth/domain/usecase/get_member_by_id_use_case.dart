import 'package:devlink_mobile_app/auth/domain/model/member.dart';

class GetMemberByIdUseCase {
  Future<Member> execute(String id) async {
    await Future.delayed(Duration(milliseconds: 700));
    return Member(
      id: 'testId',
      email: "testEmail",
      nickname: "testNickname",
      onAir: false,
      uid: "testUid",
      image: "testPhotoUrl",
    );
  }
}
