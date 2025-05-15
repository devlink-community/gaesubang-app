import '../../../auth/domain/model/member.dart';

class GetCurrentMemberUseCase {
  Future<Member> execute() async {
    await Future.delayed(Duration(milliseconds: 700));
    return Member(
      id: 'user1',
      email: "test1@example.com",
      nickname: "사용자1",
      onAir: false,
      uid: "uid1",
    );
  }
}
