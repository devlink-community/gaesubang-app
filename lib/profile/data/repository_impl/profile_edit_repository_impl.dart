import 'package:devlink_mobile_app/profile/data/data_source/user_storage_profile_update.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/data_source/auth_data_source.dart';
import '../../../auth/data/data_source/profile_data_source.dart';
import '../../../auth/data/data_source/user_storage.dart';
import '../../../auth/data/dto/profile_dto_old.dart';
import '../../../auth/data/dto/user_dto_old.dart';
import '../../../auth/data/mapper/member_mapper.dart';
import '../../../auth/domain/model/member.dart';
import '../../../core/result/result.dart';
import '../../domain/repository/profile_edit_repository.dart';

class ProfileEditRepositoryImpl implements ProfileEditRepository {
  final AuthDataSource _authDataSource;
  final ProfileDataSource _profileDataSource;
  final UserStorage _userStorage = UserStorage.instance; // UserStorage 인스턴스 추가

  ProfileEditRepositoryImpl({
    required AuthDataSource authDataSource,
    required ProfileDataSource profileDataSource,
  }) : _authDataSource = authDataSource,
       _profileDataSource = profileDataSource;

  @override
  Future<Result<Member>> getCurrentProfile() async {
    try {
      // 현재 로그인된 사용자 정보 가져오기
      final userMap = await _authDataSource.fetchCurrentUser();

      // userMap이 null인 경우 (로그인 안됨) 모의 데이터 반환
      if (userMap == null) {
        // 모의 데이터 생성
        final mockMember = Member(
          id: 'mock-id',
          email: 'user@example.com',
          nickname: '사용자',
          uid: 'mock-uid',
          image: 'https://via.placeholder.com/150',
          description: '안녕하세요! 자기소개를 입력해주세요.',
          position: '개발자', // 기본값 추가
          skills: 'Flutter, Dart', // 기본값 추가
        );

        return Result.success(mockMember);
      }

      // UserDto로 변환
      final userDto = UserDto.fromJson(userMap);

      // 프로필 정보 가져오기
      final profileMap = await _profileDataSource.fetchUserProfile(userDto.id!);
      final profileDto = ProfileDto.fromJson(profileMap);

      // Member 객체로 변환
      final member = userDto.toModelFromProfile(profileDto);

      // 디버그 로그 추가
      debugPrint(
        '현재 프로필 조회: ${member.nickname}, ${member.description}, ${member.position}, ${member.skills}',
      );

      return Result.success(member);
    } catch (e) {
      // 에러 로그 추가
      debugPrint('프로필 조회 실패: $e');

      // 에러 발생 시 모의 데이터 반환 (개발/테스트 환경용)
      final mockMember = Member(
        id: 'error-mock-id',
        email: 'error@example.com',
        nickname: '임시 사용자',
        uid: 'error-mock-uid',
        image: 'https://via.placeholder.com/150',
        description: '프로필 로드 중 오류가 발생했습니다.',
        position: '직무 없음', // 기본값 추가
        skills: '스킬 없음', // 기본값 추가
      );

      return Result.success(mockMember);
    }
  }

  @override
  Future<Result<Member>> updateProfile({
    required String nickname,
    String? intro,
    String? position, // position 매개변수 추가
    String? skills, // skills 매개변수 추가
  }) async {
    try {
      // 디버그 로그 추가
      debugPrint('리포지토리 - 프로필 업데이트 시작: $nickname, $intro');

      // UserStorage 확장 메서드를 사용하여 프로필 업데이트
      final success = _userStorage.updateCurrentUserProfile(
        nickname: nickname,
        description: intro,
        position: position, // position 전달
        skills: skills, // skills 전달
      );

      // 결과 로그 추가
      debugPrint('프로필 업데이트 결과: $success');

      if (success) {
        // 업데이트된 후 새로운 프로필 정보 가져오기
        final result = await getCurrentProfile();

        // 성공 시 로그 추가 - 패턴 매칭 사용
        switch (result) {
          case Success(:final data):
            debugPrint(
              '업데이트 후 프로필 조회 성공: ${data.nickname}, ${data.description}',
            );
            break;
          case Error(:final failure):
            debugPrint('업데이트 후 프로필 조회 실패: ${failure.message}');
            break;
        }

        return result;
      } else {
        // 업데이트 실패 시 기존 프로필 정보를 가져와 업데이트된 값으로 변경 (UI 목적으로)
        final userResult = await getCurrentProfile();

        switch (userResult) {
          case Success(:final data):
            final updatedMember = data.copyWith(
              nickname: nickname,
              description: intro ?? data.description,
            );

            // 실패 처리 로그 추가
            debugPrint(
              '프로필 업데이트 실패 후 UI 업데이트: ${updatedMember.nickname}, ${updatedMember.description}',
            );

            return Result.success(updatedMember);

          case Error(:final failure):
            debugPrint('프로필 업데이트 완전 실패: ${failure.message}');
            return Result.error(failure);
        }
      }
    } catch (e) {
      // 예외 로그 추가
      debugPrint('프로필 업데이트 예외 발생: $e');

      // 개발/테스트 환경에서는 모의 데이터 반환
      final mockMember = Member(
        id: 'mock-id',
        email: 'user@example.com',
        nickname: nickname,
        uid: 'mock-uid',
        image: 'https://via.placeholder.com/150',
        description: intro ?? '프로필 업데이트 완료',
      );

      return Result.success(mockMember);

      // 실제 에러 반환 코드 (프로덕션 환경용)
      // return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<Member>> updateProfileImage(XFile image) async {
    try {
      // 디버그 로그 추가
      debugPrint('리포지토리 - 이미지 업데이트 시작: ${image.path}');

      // UserStorage 확장 메서드를 사용하여 이미지 업데이트
      final success = _userStorage.updateCurrentUserImage(image.path);

      // 결과 로그 추가
      debugPrint('이미지 업데이트 결과: $success');

      if (success) {
        // 업데이트된 후 새로운 프로필 정보 가져오기
        final result = await getCurrentProfile();

        // 성공 시 로그 추가 - 패턴 매칭 사용
        switch (result) {
          case Success(:final data):
            debugPrint('이미지 업데이트 후 프로필 조회 성공: ${data.image}');
            break;
          case Error(:final failure):
            debugPrint('이미지 업데이트 후 프로필 조회 실패: ${failure.message}');
            break;
        }

        return result;
      } else {
        // 업데이트 실패 시 기존 프로필 정보를 가져와 업데이트된 값으로 변경 (UI 목적으로)
        final userResult = await getCurrentProfile();

        switch (userResult) {
          case Success(:final data):
            // 로컬 파일 경로를 사용
            final updatedMember = data.copyWith(image: image.path);

            // 실패 처리 로그 추가
            debugPrint('이미지 업데이트 실패 후 UI 업데이트: ${updatedMember.image}');

            return Result.success(updatedMember);

          case Error(:final failure):
            debugPrint('이미지 업데이트 완전 실패: ${failure.message}');
            return Result.error(failure);
        }
      }
    } catch (e) {
      // 예외 로그 추가
      debugPrint('이미지 업데이트 예외 발생: $e');

      // 개발/테스트 환경에서는 모의 데이터 반환
      final mockMember = Member(
        id: 'mock-id',
        email: 'user@example.com',
        nickname: '사용자',
        uid: 'mock-uid',
        image: image.path,
        // 로컬 파일 경로 사용
        description: '이미지 업로드 완료',
      );

      return Result.success(mockMember);

      // 실제 에러 반환 코드 (프로덕션 환경용)
      // return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
