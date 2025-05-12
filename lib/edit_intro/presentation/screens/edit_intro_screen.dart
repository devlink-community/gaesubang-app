import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../edit_intro_action.dart';
import '../states/edit_intro_state.dart';

class EditIntroScreen extends StatelessWidget {
  final EditIntroState state;
  final void Function(EditIntroAction action) onAction;

  const EditIntroScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 처리
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 에러 상태 처리
    if (state.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.errorMessage ?? '오류가 발생했습니다',
                style: AppTextStyles.subtitle1Medium.copyWith(
                  color: AppColorStyles.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('뒤로 가기'),
              ),
            ],
          ),
        ),
      );
    }

    // 멤버 정보가 없는 경우 처리
    final member = state.member;
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('프로필 정보를 불러올 수 없습니다')),
      );
    }

    // UI 컴포넌트 - 여기서부터는 원래 코드와 크게 다르지 않지만 StatefulWidget에서 StatelessWidget으로 변경
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정', style: AppTextStyles.heading3Bold),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, member),
    );
  }

  Widget _buildBody(BuildContext context, final member) {
    // TextEditingController는 위젯 외부에서 생성하여 전달하는 것이 좋으나,
    // 여기서는 간단히 처리
    final nicknameController = TextEditingController(text: member.nickname);
    final introController = TextEditingController(text: member.description);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileImageSection(member),
          const SizedBox(height: 24),
          _buildNicknameField(nicknameController),
          const SizedBox(height: 16),
          _buildIntroField(introController),
          const SizedBox(height: 24),
          _buildSaveButton(context, nicknameController, introController),

          // 이미지 업로드 상태 표시
          if (state.isImageUploading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // 이미지 업로드 오류 표시
          if (state.hasImageUploadError)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                state.imageUploadErrorMessage ?? '이미지 업로드 오류',
                style: AppTextStyles.body1Regular.copyWith(
                  color: AppColorStyles.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(final member) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                member.image.isNotEmpty ? NetworkImage(member.image) : null,
            child:
                member.image.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColorStyles.primary100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: '닉네임',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => onAction(EditIntroAction.onChangeNickname(value)),
    );
  }

  Widget _buildIntroField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: '소개글',
        border: OutlineInputBorder(),
      ),
      maxLines: 10,
      onChanged: (value) => onAction(EditIntroAction.onChangeMessage(value)),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    TextEditingController nicknameController,
    TextEditingController introController,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorStyles.primary100,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => onAction(const EditIntroAction.onSave()),
      child: Text(
        '저장하기',
        style: AppTextStyles.button1Medium.copyWith(color: Colors.white),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onAction(EditIntroAction.onPickImage(File(image.path)));
    }
  }
}
