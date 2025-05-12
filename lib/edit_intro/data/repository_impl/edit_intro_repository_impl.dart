import 'package:image_picker/image_picker.dart';
import '../../../auth/data/data_source/auth_data_source.dart';
import '../../../auth/data/data_source/profile_data_source.dart';
import '../../../auth/data/dto/profile_dto.dart';
import '../../../auth/data/dto/user_dto.dart';
import '../../../auth/data/mapper/member_mapper.dart';
import '../../../auth/domain/model/member.dart';
import '../../../core/result/result.dart';
import '../../domain/repository/edit_intro_repository.dart';

class EditIntroRepositoryImpl implements EditIntroRepository {
  final AuthDataSource _authDataSource;
  final ProfileDataSource _profileDataSource;

  EditIntroRepositoryImpl({
    required AuthDataSource authDataSource,
    required ProfileDataSource profileDataSource,
  }) : _authDataSource = authDataSource,
       _profileDataSource = profileDataSource;

  @override
  Future<Result<Member>> getCurrentProfile() async {
    try {
      // 현재 로그인된 사용자 정보 가져오기
      final userMap = await _authDataSource.fetchCurrentUser();
      if (userMap == null) {
        throw Exception('로그인된 사용자가 없습니다');
      }

      // UserDto로 변환
      final userDto = UserDto.fromJson(userMap);

      // 프로필 정보 가져오기
      final profileMap = await _profileDataSource.fetchUserProfile(userDto.id!);
      final profileDto = ProfileDto.fromJson(profileMap);

      // Member 객체로 변환
      final member = userDto.toModelFromProfile(profileDto);
      return Result.success(member);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<Member>> updateProfile({
    required String nickname,
    String? intro,
  }) async {
    try {
      // 실제 구현에서는 API 호출
      // 여기서는 모의 데이터 반환
      final userResult = await getCurrentProfile();

      switch (userResult) {
        case Success(:final data):
          final updatedMember = data.copyWith(
            nickname: nickname,
            description: intro ?? data.description,
          );
          return Result.success(updatedMember);

        case Error(:final failure):
          return Result.error(failure);
      }
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<Member>> updateProfileImage(XFile image) async {
    try {
      // 실제 구현에서는 이미지 업로드 API 호출
      // 여기서는 모의 데이터 반환
      final userResult = await getCurrentProfile();

      switch (userResult) {
        case Success(:final data):
          final updatedMember = data.copyWith(
            image: 'https://via.placeholder.com/150',
          );
          return Result.success(updatedMember);

        case Error(:final failure):
          return Result.error(failure);
      }
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
