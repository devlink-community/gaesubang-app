import 'package:flutter/material.dart';

import '../../../auth/data/data_source/user_storage.dart';
import '../../../auth/data/dto/profile_dto_old.dart';
import '../../../auth/data/dto/user_dto_old.dart';

/// UserStorage에 프로필 업데이트 기능을 추가하는 확장 (목업용)
// UserStorage에 프로필 업데이트 기능을 추가하는 확장 (목업용)
extension UserStorageProfileUpdate on UserStorage {
  // 현재 사용자의 닉네임 및 소개글 업데이트
  bool updateCurrentUserProfile({
    required String nickname,
    String? description,
    String? position, // position 매개변수 추가
    String? skills, // skills 매개변수 추가
  }) {
    try {
      // UserStorage 초기화
      initialize();

      final user = currentUser;
      if (user == null) {
        debugPrint('현재 로그인된 사용자가 없습니다.');
        return false;
      }

      // 프로필 정보 가져오기
      final profile = getProfileById(user.id!);
      if (profile == null) {
        debugPrint('현재 사용자의 프로필을 찾을 수 없습니다.');
        return false;
      }

      // 현재 비밀번호 - 실제로는 보안상 이렇게 하면 안 되지만 목업용으로만 사용
      String password = 'password123'; // 가정: 모든 목업 사용자의 기본 비밀번호

      // 새 UserDto (닉네임만 변경)
      final updatedUserDto = UserDto(
        id: user.id,
        email: user.email,
        nickname: nickname,
        uid: user.uid,
        agreedTermsId: user.agreedTermsId,
      );

      // 새 ProfileDto (description, position, skills 포함)
      final updatedProfileDto = ProfileDto(
        userId: user.id,
        image: profile.image,
        onAir: profile.onAir,
        description: description ?? profile.description ?? '',
        position: position ?? profile.position, // position 필드 추가
        skills: skills ?? profile.skills, // skills 필드 추가
      );

      // 현재 로그인 상태 저장
      final loggedInUserId = currentUserId;

      // 사용자 정보 업데이트 (addUser는 기존 사용자를 덮어씀)
      addUser(updatedUserDto, updatedProfileDto, password);

      // 로그인 상태 복원
      if (loggedInUserId != null) {
        login(loggedInUserId);
      }

      debugPrint('프로필 업데이트 성공: $nickname, $description, $position, $skills');
      return true;
    } catch (e) {
      debugPrint('프로필 업데이트 실패: $e');
      return false;
    }
  }

  // 현재 사용자의 프로필 이미지 업데이트 (이 부분은 변경하지 않습니다)
  bool updateCurrentUserImage(String imagePath) {
    // 코드는 그대로 유지
    try {
      // UserStorage 초기화
      initialize();

      final user = currentUser;
      if (user == null) {
        debugPrint('현재 로그인된 사용자가 없습니다.');
        return false;
      }

      // 프로필 정보 가져오기
      if (user.id == null) {
        debugPrint('현재 로그인된 사용자의 ID가 없습니다.');
        return false;
      }
      final profile = getProfileById(user.id!);
      if (profile == null) {
        debugPrint('현재 사용자의 프로필을 찾을 수 없습니다.');
        return false;
      }

      // 현재 비밀번호 - 실제로는 보안상 이렇게 하면 안 되지만 목업용으로만 사용
      String password = 'password123'; // 가정: 모든 목업 사용자의 기본 비밀번호

      // 새 ProfileDto 생성 (이미지 경로만 변경하고 다른 필드는 유지)
      final updatedProfileDto = ProfileDto(
        userId: profile.userId,
        image: imagePath, // 변경된 이미지 경로
        onAir: profile.onAir,
        description: profile.description,
        position: profile.position, // position 유지
        skills: profile.skills, // skills 유지
      );

      // 현재 로그인 상태 저장
      final loggedInUserId = currentUserId;

      // 사용자 정보 업데이트 (addUser는 기존 사용자를 덮어씀)
      addUser(user, updatedProfileDto, password);

      // 로그인 상태 복원
      if (loggedInUserId != null) {
        login(loggedInUserId);
      }

      debugPrint('이미지 업데이트 성공: $imagePath');
      return true;
    } catch (e) {
      debugPrint('이미지 업데이트 실패: $e');
      return false;
    }
  }
}
