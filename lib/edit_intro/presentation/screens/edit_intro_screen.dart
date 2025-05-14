import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';
import '../../../group/presentation/group_setting/group_settings_action.dart';
import '../../../group/presentation/labeled_text_field.dart';
import '../edit_intro_action.dart';
import '../states/edit_intro_state.dart';

class EditIntroScreen extends StatefulWidget {
  final EditIntroState state;
  final void Function(EditIntroAction action) onAction;

  const EditIntroScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<EditIntroScreen> createState() => _EditIntroScreenState();
}

class _EditIntroScreenState extends State<EditIntroScreen> {
  // 로컬 이미지 파일을 저장할 변수 추가
  File? _localImageFile;

  // 텍스트 컨트롤러 선언
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 초기 값 설정
    _updateTextControllers();
  }

  @override
  void didUpdateWidget(covariant EditIntroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상태가 변경되면 컨트롤러 업데이트
    if (oldWidget.state != widget.state) {
      _updateTextControllers();
    }
  }

  void _updateTextControllers() {
    final member = widget.state.member;
    if (member != null) {
      _nicknameController.text = member.nickname;
      _descriptionController.text = member.description;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 처리
    if (widget.state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 에러 상태 처리
    if (widget.state.hasError) {
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
                widget.state.errorMessage ?? '오류가 발생했습니다',
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
    final member = widget.state.member;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정', style: AppTextStyles.heading3Bold),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileImageSection(member),
            const SizedBox(height: 24),

            // 닉네임 필드 (LabeledTextField 사용)
            LabeledTextField(
              label: '닉네임',
              hint: '닉네임을 입력하세요',
              controller: _nicknameController,
              onChanged:
                  (value) =>
                      widget.onAction(EditIntroAction.onChangeNickname(value)),
            ),

            const SizedBox(height: 16),

            // 소개글 필드 (LabeledTextField 사용)
            LabeledTextField(
              label: '소개글',
              hint: '자신을 소개하는 글을 작성해보세요',
              controller: _descriptionController,
              maxLines: 5,
              onChanged:
                  (value) =>
                      widget.onAction(EditIntroAction.onChangeMessage(value)),
            ),

            const SizedBox(height: 24),
            _buildSaveButton(),

            // 이미지 업로드 상태 표시
            if (widget.state.isImageUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // 이미지 업로드 오류 표시
            if (widget.state.hasImageUploadError)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  widget.state.imageUploadErrorMessage ?? '이미지 업로드 오류',
                  style: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(final member) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            // 로컬 이미지가 있으면 File 이미지를, 없으면 네트워크 이미지나 기본 아이콘 표시
            backgroundImage:
                _localImageFile != null
                    ? FileImage(_localImageFile!)
                    : (member.image.isNotEmpty
                        ? NetworkImage(member.image)
                        : null),
            child:
                (member.image.isEmpty && _localImageFile == null)
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorStyles.primary100,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => widget.onAction(const EditIntroAction.onSave()),
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
      // 로컬 상태에 이미지 파일 저장하고 UI 갱신
      setState(() {
        _localImageFile = File(image.path);
      });

      // 액션을 통해 이미지 업로드 프로세스 시작
      widget.onAction(EditIntroAction.onPickImage(_localImageFile!));
    }
  }
}
