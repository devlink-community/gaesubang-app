import 'dart:io';

import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/styles/app_color_styles.dart';
import '../../../../core/styles/app_text_styles.dart';
import '../../../../group/presentation/component/labeled_text_field.dart';

class ProfileEditScreen extends StatefulWidget {
  final ProfileEditState state;
  final void Function(ProfileEditAction action) onAction;

  const ProfileEditScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // 로컬 이미지 파일을 저장할 변수 추가
  File? _localImageFile;

  // 텍스트 컨트롤러 선언
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();
  final _skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateTextControllers();
    _updateLocalImageFile();
  }

  @override
  void didUpdateWidget(covariant ProfileEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateTextControllers();
      _updateLocalImageFile();
    }
  }

  void _updateTextControllers() {
    final member = widget.state.member;
    if (member != null) {
      _nicknameController.text = member.nickname;
      _descriptionController.text = member.description;
      _positionController.text = member.position ?? '';
      _skillsController.text = member.skills ?? '';
    }
  }

  void _updateLocalImageFile() {
    final member = widget.state.member;
    if (member != null &&
        member.image.isNotEmpty &&
        member.image.startsWith('/')) {
      if (_localImageFile?.path != member.image) {
        setState(() {
          _localImageFile = File(member.image);
        });
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태에 따른 화면 분기 (가이드 준수)
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정', style: AppTextStyles.heading6Bold),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 로딩 상태 처리
    if (widget.state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 상태 처리
    if (widget.state.hasError) {
      return _buildErrorView();
    }

    // 멤버 정보가 없는 경우
    final member = widget.state.member;
    if (member == null) {
      return const Center(child: Text('프로필 정보를 불러올 수 없습니다'));
    }

    // 정상 상태 - 편집 폼
    return _buildEditForm(member);
  }

  Widget _buildErrorView() {
    return Center(
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
    );
  }

  Widget _buildEditForm(member) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileImageSection(member),
          const SizedBox(height: 24),

          LabeledTextField(
            label: '닉네임',
            hint: '닉네임을 입력하세요',
            controller: _nicknameController,
            onChanged:
                (value) =>
                    widget.onAction(ProfileEditAction.onChangeNickname(value)),
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '직무',
            hint: '직무를 입력하세요 (예: 백엔드 개발자, 프론트엔드 개발자)',
            controller: _positionController,
            onChanged:
                (value) =>
                    widget.onAction(ProfileEditAction.onChangePosition(value)),
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '스킬',
            hint: '보유한 스킬을 입력하세요 (예: Flutter, React, Python)',
            controller: _skillsController,
            onChanged:
                (value) =>
                    widget.onAction(ProfileEditAction.onChangeSkills(value)),
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '소개글',
            hint: '자신을 소개하는 글을 작성해보세요',
            controller: _descriptionController,
            maxLines: 5,
            onChanged:
                (value) =>
                    widget.onAction(ProfileEditAction.onChangeMessage(value)),
          ),
          const SizedBox(height: 24),

          _buildSaveButton(),

          // 이미지 업로드 상태 표시
          if (widget.state.isImageUploading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],

          // 이미지 업로드 오류 표시
          if (widget.state.hasImageUploadError) ...[
            const SizedBox(height: 16),
            Text(
              widget.state.imageUploadErrorMessage ?? '이미지 업로드 오류',
              style: AppTextStyles.body1Regular.copyWith(
                color: AppColorStyles.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(member) {
    return Center(
      child: Stack(
        children: [
          _buildProfileImage(member),
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

  Widget _buildProfileImage(member) {
    // 로컬 이미지 파일이 있는 경우
    if (_localImageFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_localImageFile!),
        backgroundColor: Colors.grey.shade200,
      );
    }

    // 이미지 경로가 있는 경우
    if (member.image.isNotEmpty) {
      if (member.image.startsWith('/')) {
        // 로컬 파일 경로
        return CircleAvatar(
          radius: 50,
          backgroundImage: FileImage(File(member.image)),
          backgroundColor: Colors.grey.shade200,
        );
      } else {
        // 네트워크 이미지 URL
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(member.image),
          backgroundColor: Colors.grey.shade200,
        );
      }
    }

    // 이미지가 없는 경우 기본 아이콘 표시
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey.shade100,
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
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
      onPressed: () => widget.onAction(const ProfileEditAction.onSave()),
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
      widget.onAction(ProfileEditAction.onPickImage(_localImageFile!));
    }
  }
}
