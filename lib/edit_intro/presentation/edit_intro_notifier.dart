import 'dart:io';

import 'package:devlink_mobile_app/auth/domain/model/member.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/edit_intro_action.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/states/edit_intro_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_intro_notifier.g.dart';

@riverpod
class EditIntroNotifier extends _$EditIntroNotifier {
  @override
  EditIntroState build() {
    // 초기 상태에서 바로 모의 데이터 로드
    _loadMockProfile();
    return const EditIntroState();
  }

  Future<void> _loadMockProfile() async {
    state = state.copyWith(isLoading: true);

    // 약간의 지연 효과를 주어 로딩 상태를 보여주기
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // 모의 데이터 생성
      final mockMember = Member(
        id: '1',
        email: 'user@example.com',
        nickname: '개발자',
        uid: 'dev123',
        image: 'https://via.placeholder.com/150',
        description: '안녕하세요! 열정적인 개발자입니다.',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        member: mockMember,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '프로필 정보를 불러올 수 없습니다: ${e.toString()}',
      );
    }
  }

  Future<void> onAction(EditIntroAction action) async {
    switch (action) {
      case OnChangeNickname(:final nickname):
        if (state.member != null) {
          final updatedMember = state.member!.copyWith(nickname: nickname);
          state = state.copyWith(member: updatedMember);
        }

      case OnChangeMessage(:final message):
        if (state.member != null) {
          final updatedMember = state.member!.copyWith(description: message);
          state = state.copyWith(member: updatedMember);
        }

      case OnSave():
        await _saveMockProfile();

      case OnPickImage(:final image):
        await _handleImageSelected(image);
    }
  }

  Future<void> _saveMockProfile() async {
    if (state.member == null) return;

    state = state.copyWith(isLoading: true);

    // 약간의 지연 효과 추가
    await Future.delayed(const Duration(milliseconds: 500));

    // 모의 저장 완료 상태로 전환
    state = state.copyWith(isLoading: false, isSuccess: true);
  }

  Future<void> _handleImageSelected(File image) async {
    state = state.copyWith(isImageUploading: true);

    try {
      // 업로드 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));

      // 이미지 업로드 성공 시 member 객체 업데이트
      if (state.member != null) {
        // 실제로는 이미지 URL을 받아와야 하지만, 여기서는 목업
        // 예시로 임시 URL 사용
        final updatedMember = state.member!.copyWith(
          image: 'https://via.placeholder.com/150',
        );

        state = state.copyWith(
          isImageUploading: false,
          isImageUploadSuccess: true,
          member: updatedMember,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isImageUploading: false,
        isImageUploadError: true,
        imageUploadErrorMessage: '이미지 업로드에 실패했습니다: ${e.toString()}',
      );
    }
  }
}
