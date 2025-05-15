import 'package:devlink_mobile_app/edit_intro/data/data_source/user_storage_profile_update.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/data_source/user_storage.dart';
import '../../../auth/data/dto/user_dto.dart';

class MockProfileUpdater {
  final UserStorage _storage = UserStorage.instance;

  // 현재 로그인된 사용자 가져오기
  UserDto? getCurrentUser() {
    _storage.initialize();
    return _storage.currentUser;
  }

  // 사용자 로그인 (데모 용도)
  void login(String userId) {
    _storage.login(userId);
  }

  // 프로필 이미지 업데이트
  Future<bool> updateProfileImage(XFile image) async {
    try {
      // 확장 메서드를 사용하여 이미지 업데이트
      final result = _storage.updateCurrentUserImage(image.path);

      if (result) {
        debugPrint('이미지 업데이트 성공: ${image.path}');
      } else {
        debugPrint('이미지 업데이트 실패');
      }

      return result;
    } catch (e) {
      debugPrint('이미지 업데이트 예외 발생: $e');
      return false;
    }
  }

  // 프로필 정보 업데이트
  Future<bool> updateProfile({
    required String nickname,
    String? description,
  }) async {
    try {
      // 확장 메서드를 사용하여 프로필 업데이트
      final result = _storage.updateCurrentUserProfile(
        nickname: nickname,
        description: description,
      );

      if (result) {
        debugPrint('프로필 업데이트 성공: $nickname, $description');
      } else {
        debugPrint('프로필 업데이트 실패');
      }

      return result;
    } catch (e) {
      debugPrint('프로필 업데이트 예외 발생: $e');
      return false;
    }
  }

  // 현재 로그인된 사용자의 프로필 이미지 가져오기
  String? getCurrentUserImagePath() {
    final user = getCurrentUser();
    if (user == null) return null;

    final profile = _storage.getProfileById(user.id!);
    return profile?.image;
  }

  // 현재 로그인된 사용자의 닉네임 가져오기
  String? getCurrentUserNickname() {
    final user = getCurrentUser();
    return user?.nickname;
  }

  // 현재 로그인된 사용자의 소개글 가져오기
  String? getCurrentUserDescription() {
    final user = getCurrentUser();
    if (user == null) return null;

    final profile = _storage.getProfileById(user.id!);
    return profile?.description;
  }
}
