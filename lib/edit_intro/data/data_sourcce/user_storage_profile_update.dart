import 'package:flutter/material.dart';

import '../../../auth/data/data_source/user_storage.dart';
import '../../../auth/data/dto/profile_dto.dart';
import '../../../auth/data/dto/user_dto.dart';

/// UserStorage에 프로필 업데이트 기능을 추가하는 확장 (목업용)
extension UserStorageProfileUpdate on UserStorage {
  // 현재 사용자의 닉네임 및 소개글 업데이트
  bool updateCurrentUserProfile({
    required String nickname,
    String? description,
  }) {
    try {
      // UserStorage 초기화
      initialize();

      final user = currentUser;
      if (user == null) return false;

      // 프로필 정보 가져오기
      final profile = getProfileById(user.id!);
      if (profile == null) return false;

      // 현재 비밀번호 - 실제로는 보안상 이렇게 하면 안 되지만 목업용으로만 사용
      final password = 'password123'; // 가정: 모든 목업 사용자의 기본 비밀번호

      // 새 UserDto와 ProfileDto 생성
      final updatedUserDto = UserDto(
        id: user.id,
        email: user.email, // 기존 이메일 유지
        nickname: nickname, // 변경된 닉네임
        uid: user.uid,
        agreedTermsId: user.agreedTermsId,
      );

      final updatedProfileDto = ProfileDto(
        userId: user.id,
        image: profile.image,
        onAir: profile.onAir,
        description: description ?? profile.description ?? '',
      );

      // 현재 로그인 상태 저장
      final loggedInUserId = this.currentUserId;

      // 사용자 정보 업데이트 (addUser는 기존 사용자를 덮어씀)
      addUser(updatedUserDto, updatedProfileDto, password);

      // 로그인 상태 복원
      if (loggedInUserId != null) {
        login(loggedInUserId);
      }

      debugPrint('프로필 업데이트 성공: $nickname, $description');
      return true;
    } catch (e) {
      debugPrint('프로필 업데이트 실패: $e');
      return false;
    }
  }

  // 현재 사용자의 프로필 이미지 업데이트
  bool updateCurrentUserImage(String imagePath) {
    try {
      // UserStorage 초기화
      initialize();

      final user = currentUser;
      if (user == null) return false;

      // 프로필 정보 가져오기
      final profile = getProfileById(user.id!);
      if (profile == null) return false;

      // 현재 비밀번호 - 실제로는 보안상 이렇게 하면 안 되지만 목업용으로만 사용
      final password = 'password123'; // 가정: 모든 목업 사용자의 기본 비밀번호

      // 새 ProfileDto 생성 (이미지 경로만 변경)
      final updatedProfileDto = ProfileDto(
        userId: profile.userId,
        image: imagePath, // 변경된 이미지 경로
        onAir: profile.onAir,
        description: profile.description,
      );

      // 현재 로그인 상태 저장
      final loggedInUserId = this.currentUserId;

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
