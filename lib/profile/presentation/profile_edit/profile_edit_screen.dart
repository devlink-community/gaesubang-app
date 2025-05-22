import 'dart:async';
import 'dart:io';

import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_action.dart';
import 'package:devlink_mobile_app/profile/presentation/profile_edit/profile_edit_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  bool _isImageUploading = false; // 이미지 업로드 상태 추가

  // 텍스트 컨트롤러 선언
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positionController = TextEditingController();
  final _skillsController = TextEditingController();

  // Debouncing을 위한 Timer들
  Timer? _nicknameDebouncer;
  Timer? _descriptionDebouncer;
  Timer? _positionDebouncer;
  Timer? _skillsDebouncer;

  // 현재 업데이트 중인지 확인하는 플래그
  bool _isUpdatingFromState = false;

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
      _updateTextControllersIfNeeded();
      _updateLocalImageFileIfNeeded();
    }
  }

  void _updateTextControllersIfNeeded() {
    final member = widget.state.editingProfile;
    if (member == null) return;

    _isUpdatingFromState = true;

    // 현재 컨트롤러 값과 상태 값이 다를 때만 업데이트
    if (_nicknameController.text != member.nickname) {
      _nicknameController.value = _nicknameController.value.copyWith(
        text: member.nickname,
        selection: TextSelection.collapsed(offset: member.nickname.length),
      );
    }

    if (_descriptionController.text != member.description) {
      _descriptionController.value = _descriptionController.value.copyWith(
        text: member.description,
        selection: TextSelection.collapsed(offset: member.description.length),
      );
    }

    final position = member.position ?? '';
    if (_positionController.text != position) {
      _positionController.value = _positionController.value.copyWith(
        text: position,
        selection: TextSelection.collapsed(offset: position.length),
      );
    }

    final skills = member.skills ?? '';
    if (_skillsController.text != skills) {
      _skillsController.value = _skillsController.value.copyWith(
        text: skills,
        selection: TextSelection.collapsed(offset: skills.length),
      );
    }

    // 다음 프레임에서 플래그 해제
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdatingFromState = false;
    });
  }

  void _updateTextControllers() {
    final member = widget.state.editingProfile;
    if (member != null) {
      _nicknameController.text = member.nickname;
      _descriptionController.text = member.description;
      _positionController.text = member.position ?? '';
      _skillsController.text = member.skills ?? '';
    }
  }

  void _updateLocalImageFile() {
    final member = widget.state.editingProfile;
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

  // 개선된 이미지 파일 업데이트 - 업로드 중이 아닐 때만 업데이트
  void _updateLocalImageFileIfNeeded() {
    final member = widget.state.editingProfile;

    // 업로드 중이면 로컬 이미지 파일을 그대로 유지
    if (_isImageUploading) return;

    if (member != null &&
        member.image.isNotEmpty &&
        member.image.startsWith('/')) {
      if (_localImageFile?.path != member.image) {
        setState(() {
          _localImageFile = File(member.image);
        });
      }
    } else if (member != null &&
        member.image.isNotEmpty &&
        !member.image.startsWith('/')) {
      // 네트워크 이미지로 업데이트된 경우 로컬 파일 초기화
      if (_localImageFile != null) {
        setState(() {
          _localImageFile = null;
        });
      }
    }
  }

  // Debounced onChanged 핸들러들
  void _onNicknameChanged(String value) {
    if (_isUpdatingFromState) return; // 상태에서 업데이트 중이면 무시

    _nicknameDebouncer?.cancel();
    _nicknameDebouncer = Timer(const Duration(milliseconds: 300), () {
      widget.onAction(ProfileEditAction.onChangeNickname(value));
    });
  }

  void _onDescriptionChanged(String value) {
    if (_isUpdatingFromState) return;

    _descriptionDebouncer?.cancel();
    _descriptionDebouncer = Timer(const Duration(milliseconds: 300), () {
      widget.onAction(ProfileEditAction.onChangeDescription(value));
    });
  }

  void _onPositionChanged(String value) {
    if (_isUpdatingFromState) return;

    _positionDebouncer?.cancel();
    _positionDebouncer = Timer(const Duration(milliseconds: 300), () {
      widget.onAction(ProfileEditAction.onChangePosition(value));
    });
  }

  void _onSkillsChanged(String value) {
    if (_isUpdatingFromState) return;

    _skillsDebouncer?.cancel();
    _skillsDebouncer = Timer(const Duration(milliseconds: 300), () {
      widget.onAction(ProfileEditAction.onChangeSkills(value));
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _descriptionController.dispose();
    _positionController.dispose();
    _skillsController.dispose();

    // Timer들 정리
    _nicknameDebouncer?.cancel();
    _descriptionDebouncer?.cancel();
    _positionDebouncer?.cancel();
    _skillsDebouncer?.cancel();

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

    // 프로필 상태에 따른 분기
    return switch (widget.state.profileState) {
      AsyncError() => _buildErrorView(),
      AsyncData(:final value) => _buildEditForm(value),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      _ => _buildErrorView(),
    };
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.state.profileState.error.toString(),
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
            onChanged: _onNicknameChanged, // debounced 핸들러 사용
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '직무',
            hint: '직무를 입력하세요 (예: 백엔드 개발자, 프론트엔드 개발자)',
            controller: _positionController,
            onChanged: _onPositionChanged, // debounced 핸들러 사용
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '스킬',
            hint: '보유한 스킬을 입력하세요 (예: Flutter, React, Python)',
            controller: _skillsController,
            onChanged: _onSkillsChanged, // debounced 핸들러 사용
          ),
          const SizedBox(height: 16),

          LabeledTextField(
            label: '소개글',
            hint: '자신을 소개하는 글을 작성해보세요',
            controller: _descriptionController,
            maxLines: 5,
            onChanged: _onDescriptionChanged, // debounced 핸들러 사용
          ),
          const SizedBox(height: 24),

          _buildSaveButton(),

          // 이미지 업로드 상태 표시 - 개선
          if (_isImageUploading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '이미지 업로드 중...',
                  style: AppTextStyles.body2Regular.copyWith(
                    color: AppColorStyles.primary100,
                  ),
                ),
              ],
            ),
          ],

          // 이미지 업로드 오류 표시
          if (widget.state.saveError != null && !_isImageUploading) ...[
            const SizedBox(height: 16),
            Text(
              widget.state.saveError!,
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
                color:
                    _isImageUploading
                        ? AppColorStyles.gray60
                        : AppColorStyles.primary100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    _isImageUploading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _isImageUploading ? null : _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(member) {
    // 우선순위: 로컬 이미지 파일 > 네트워크 이미지 > 기본 아이콘

    // 1. 로컬 이미지 파일이 있는 경우 (최우선)
    if (_localImageFile != null && _localImageFile!.existsSync()) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_localImageFile!),
        backgroundColor: Colors.grey.shade200,
      );
    }

    // 2. 기존 이미지가 있는 경우
    if (member.image.isNotEmpty) {
      if (member.image.startsWith('/')) {
        // 로컬 파일 경로
        return CircleAvatar(
          radius: 50,
          backgroundImage: FileImage(File(member.image)),
          backgroundColor: Colors.grey.shade200,
          onBackgroundImageError: (exception, stackTrace) {
            // 에러 발생 시 기본 아이콘으로 폴백
            debugPrint('로컬 이미지 로딩 오류: $exception');
          },
        );
      } else {
        // 네트워크 이미지 URL
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(member.image),
          backgroundColor: Colors.grey.shade200,
          onBackgroundImageError: (exception, stackTrace) {
            // 에러 발생 시 기본 아이콘으로 폴백
            debugPrint('네트워크 이미지 로딩 오류: $exception');
          },
        );
      }
    }

    // 3. 이미지가 없는 경우 기본 아이콘 표시
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
      onPressed:
          widget.state.isSaving
              ? null
              : () => widget.onAction(const ProfileEditAction.saveProfile()),
      child:
          widget.state.isSaving
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '저장 중...',
                    style: AppTextStyles.button1Medium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              )
              : Text(
                '저장하기',
                style: AppTextStyles.button1Medium.copyWith(
                  color: Colors.white,
                ),
              ),
    );
  }

  Future<void> _pickImage() async {
    if (_isImageUploading) return; // 업로드 중이면 무시

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 즉시 UI 업데이트를 위해 로컬 상태 설정
      setState(() {
        _localImageFile = File(image.path);
        _isImageUploading = true; // 업로드 시작
      });

      // 백그라운드에서 이미지 업로드 프로세스 시작
      widget.onAction(ProfileEditAction.onChangeImage(_localImageFile!));

      // 업로드 완료를 기다리기 위한 리스너 (간단한 타이머로 대체)
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isImageUploading = false; // 업로드 완료
          });
        }
      });
    }
  }
}
