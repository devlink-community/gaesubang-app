import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../edit_intro_action.dart';
import '../states/edit_intro_state.dart';

class EditIntroScreen extends StatelessWidget {
  final EditIntroState state;
  final Future<void> Function(EditIntroAction action) onAction;

  const EditIntroScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.hasError) {
      return Scaffold(
        body: Center(child: Text(state.errorMessage ?? '오류가 발생했습니다')),
      );
    }

    final member = state.member;
    if (member == null) {
      return const Scaffold(body: Center(child: Text('프로필 정보를 불러올 수 없습니다')));
    }

    // TextEditingController 생성은 필요할 때만 지역 변수로 사용
    final nicknameController = TextEditingController(text: member.nickname);
    final introController = TextEditingController(text: member.description);
    final formKey = GlobalKey<FormState>();

    // controller dispose는 StatelessWidget에서는 관리할 수 없음
    // 이 경우 Root에서 관리하거나, 더 간단한 방식으로 구현해야 함

    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 수정', style: AppTextStyles.heading3Bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          member.image.isNotEmpty
                              ? NetworkImage(member.image)
                              : null,
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
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          onPressed: () => _pickImage(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
                onChanged: (value) {
                  onAction(EditIntroAction.onChangeNickname(value));
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: introController,
                decoration: const InputDecoration(
                  labelText: '소개글',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  onAction(EditIntroAction.onChangeMessage(value));
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorStyles.primary100,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _saveProfile(context, formKey),
                child: Text(
                  '저장하기',
                  style: AppTextStyles.button1Medium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await onAction(EditIntroAction.onPickImage(File(image.path)));
    }
  }

  Future<void> _saveProfile(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      await onAction(const EditIntroAction.onSave());
    }
  }
}
