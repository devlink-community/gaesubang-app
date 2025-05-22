// lib/group/presentation/group_setting/group_settings_screen.dart
import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/component/tag_input_field.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class GroupSettingsScreen extends StatefulWidget {
  final GroupSettingsState state;
  final void Function(GroupSettingsAction action) onAction;

  const GroupSettingsScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _memberCountController = TextEditingController();

  // 최대 설명 길이 상수
  static const int _maxDescriptionLength = 1000;

  @override
  void initState() {
    super.initState();
    _updateTextControllers();
  }

  @override
  void didUpdateWidget(covariant GroupSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 상태가 변경되면 컨트롤러 업데이트
    if (oldWidget.state.name != widget.state.name ||
        oldWidget.state.description != widget.state.description) {
      _updateTextControllers();
    }

    // 멤버 카운트 컨트롤러 업데이트
    if (oldWidget.state.limitMemberCount != widget.state.limitMemberCount) {
      _memberCountController.text = widget.state.limitMemberCount.toString();
    }
  }

  void _updateTextControllers() {
    _nameController.text = widget.state.name;
    _descriptionController.text = widget.state.description;
    _memberCountController.text = widget.state.limitMemberCount.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.state.group is AsyncLoading || widget.state.isSubmitting;
    final isEditing = widget.state.isEditing;
    final isOwner = widget.state.isOwner; // 방장 여부

    // 현재 입력된 글자 수
    final currentDescriptionLength = _descriptionController.text.length;
    // 글자 수에 따른 색상 설정
    final Color counterColor =
        currentDescriptionLength > _maxDescriptionLength * 0.9
            ? (currentDescriptionLength >= _maxDescriptionLength
                ? Colors.red
                : Colors.orange)
            : AppColorStyles.gray80;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('그룹 설정', style: AppTextStyles.heading6Bold),
        actions: [
          if (!isLoading && isOwner)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          if (isEditing) {
                            widget.onAction(const GroupSettingsAction.save());
                          } else {
                            widget.onAction(
                              const GroupSettingsAction.toggleEditMode(),
                            );
                          }
                        },
                style: TextButton.styleFrom(
                  backgroundColor:
                      isEditing
                          ? AppColorStyles.primary100
                          : AppColorStyles.primary100.withValues(alpha: 0.1),
                  foregroundColor:
                      isEditing ? Colors.white : AppColorStyles.primary100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isEditing ? '완료' : '수정',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '그룹 정보를 불러오는 중...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 에러 메시지
                          if (widget.state.errorMessage != null)
                            _buildErrorMessage(),

                          // 썸네일 선택기
                          _buildImageSelectorWithUploadStatus(),
                          const SizedBox(height: 32),

                          // 그룹 이름 - 트렌디한 텍스트 필드로 교체
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  '그룹 이름',
                                  style: AppTextStyles.subtitle1Bold.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  style: AppTextStyles.body1Regular,
                                  enabled: isEditing,
                                  decoration: InputDecoration(
                                    hintText: '그룹 이름을 입력하세요',
                                    hintStyle: AppTextStyles.body1Regular
                                        .copyWith(color: AppColorStyles.gray60),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon:
                                        isEditing &&
                                                _nameController.text.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColorStyles.gray60,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _nameController.clear();
                                                widget.onAction(
                                                  const GroupSettingsAction.nameChanged(
                                                    '',
                                                  ),
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                  onChanged:
                                      (value) => widget.onAction(
                                        GroupSettingsAction.nameChanged(value),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 그룹 설명 - 트렌디한 텍스트 영역으로 교체
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '그룹 설명',
                                      style: AppTextStyles.subtitle1Bold
                                          .copyWith(fontSize: 16),
                                    ),
                                    // 글자 수 카운터
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: counterColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$currentDescriptionLength/$_maxDescriptionLength',
                                        style: TextStyle(
                                          color: counterColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _descriptionController,
                                  style: AppTextStyles.body1Regular,
                                  maxLines: 5,
                                  maxLength: _maxDescriptionLength,
                                  enabled: isEditing,
                                  decoration: InputDecoration(
                                    hintText:
                                        '그룹에 대한 설명을 입력하세요 (최대 $_maxDescriptionLength자)',
                                    hintStyle: AppTextStyles.body1Regular
                                        .copyWith(color: AppColorStyles.gray60),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '',
                                    // 기본 카운터 숨김
                                    suffixIcon:
                                        isEditing &&
                                                _descriptionController
                                                    .text
                                                    .isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColorStyles.gray60,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _descriptionController.clear();
                                                setState(() {}); // UI 업데이트
                                                widget.onAction(
                                                  const GroupSettingsAction.descriptionChanged(
                                                    '',
                                                  ),
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // 글자 수 카운터 업데이트
                                    widget.onAction(
                                      GroupSettingsAction.descriptionChanged(
                                        value,
                                      ),
                                    );
                                  },
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      _maxDescriptionLength,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 멤버 제한
                          _buildMemberLimitSection(),
                          const SizedBox(height: 32),

                          // 태그 입력 영역
                          _buildTagInputSection(isEditing),
                          const SizedBox(height: 32),

                          // 멤버 목록 (읽기 전용) - 편집 모드가 아닐 때만 표시
                          if (!isEditing) _buildMemberList(),
                          const SizedBox(height: 32),

                          // 그룹 탈퇴 버튼
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 32),
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => widget.onAction(
                                    const GroupSettingsAction.leaveGroup(),
                                  ),
                              icon: const Icon(Icons.exit_to_app, size: 20),
                              label: const Text('그룹 탈퇴'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // 업로드 상태가 포함된 이미지 선택기
  Widget _buildImageSelectorWithUploadStatus() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // 기본 이미지 컨테이너
              Material(
                elevation: 6,
                shadowColor: AppColorStyles.primary100.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: GestureDetector(
                  onTap:
                      widget.state.isEditing &&
                              widget.state.isOwner &&
                              !widget.state.isImageProcessing
                          ? () => widget.onAction(
                            const GroupSettingsAction.selectImage(),
                          )
                          : null,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          widget.state.displayImagePath == null
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColorStyles.primary60.withValues(
                                    alpha: 0.2,
                                  ),
                                  AppColorStyles.primary100.withValues(
                                    alpha: 0.3,
                                  ),
                                ],
                              )
                              : null,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child:
                          widget.state.displayImagePath == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 36,
                                      color: AppColorStyles.primary100,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.state.isEditing &&
                                            widget.state.isOwner
                                        ? '그룹 이미지 추가'
                                        : '그룹 이미지',
                                    style: TextStyle(
                                      color: AppColorStyles.primary100,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                              : _buildImageBySourceType(
                                widget.state.displayImagePath!,
                              ),
                    ),
                  ),
                ),
              ),

              // 업로드 진행률 오버레이
              if (widget.state.isImageUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 원형 진행 표시기
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: widget.state.uploadProgress,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.state.imageUploadStatusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // 업로드 완료 체크 아이콘
              if (widget.state.isImageUploadCompleted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.9),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '업로드 완료!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 업로드 실패 아이콘
              if (widget.state.isImageUploadFailed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.9),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '업로드 실패',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed:
                              () => widget.onAction(
                                const GroupSettingsAction.selectImage(),
                              ),
                          child: const Text(
                            '다시 시도',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 상태별 설명 텍스트
          Text(
            widget.state.isImageUploading
                ? widget.state.imageUploadStatusMessage
                : widget.state.isImageUploadCompleted
                ? '이미지 업로드가 완료되었습니다!'
                : widget.state.isImageUploadFailed
                ? '이미지 업로드에 실패했습니다'
                : '그룹을 대표하는 이미지를 선택하세요',
            style: TextStyle(
              fontSize: 14,
              color:
                  widget.state.isImageUploadFailed
                      ? Colors.red
                      : widget.state.isImageUploadCompleted
                      ? Colors.green
                      : AppColorStyles.gray80,
              fontWeight:
                  widget.state.isImageProcessing
                      ? FontWeight.w500
                      : FontWeight.normal,
            ),
          ),

          // 이미지가 있을 경우 삭제 버튼 추가
          if (widget.state.displayImagePath != null &&
              widget.state.isEditing &&
              widget.state.isOwner &&
              !widget.state.isImageProcessing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  widget.onAction(
                    const GroupSettingsAction.imageUrlChanged(null),
                  );
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  '이미지 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberLimitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '멤버 제한',
            style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),

        // 세련된 슬라이더
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: AppColorStyles.primary100,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayColor: AppColorStyles.primary100.withValues(alpha: 0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: widget.state.limitMemberCount.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            label: widget.state.limitMemberCount.toString(),
            onChanged:
                widget.state.isEditing
                    ? (value) {
                      // 슬라이더 변경 시 컨트롤러 업데이트
                      _memberCountController.text = value.toInt().toString();
                      widget.onAction(
                        GroupSettingsAction.limitMemberCountChanged(
                          value.toInt(),
                        ),
                      );
                    }
                    : null,
          ),
        ),

        const SizedBox(height: 16),

        // 최대 인원수 컨트롤러
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorStyles.primary100.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColorStyles.primary100.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('최대 인원수', style: AppTextStyles.body1Regular),
              const SizedBox(width: 16),

              // 인원수 감소 버튼
              _buildMemberCountButton(
                icon: Icons.remove,
                onPressed:
                    widget.state.isEditing && widget.state.limitMemberCount > 2
                        ? () {
                          final newValue = widget.state.limitMemberCount - 1;
                          // 컨트롤러 업데이트 먼저
                          _memberCountController.text = newValue.toString();
                          // 그다음 상태 업데이트
                          widget.onAction(
                            GroupSettingsAction.limitMemberCountChanged(
                              newValue,
                            ),
                          );
                        }
                        : null,
              ),

              // 인원수 입력창
              Container(
                width: 56,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorStyles.gray40),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _memberCountController,
                    enabled: widget.state.isEditing,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTextStyles.subtitle1Bold.copyWith(
                      color: AppColorStyles.primary100,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onEditingComplete: () {
                      // 편집이 완료된 후에 상태 업데이트
                      final value = _memberCountController.text;
                      if (value.isEmpty) {
                        // 빈 값인 경우 기본값으로 설정
                        _memberCountController.text = "2";
                        widget.onAction(
                          const GroupSettingsAction.limitMemberCountChanged(2),
                        );
                        return;
                      }

                      final count = int.tryParse(value);
                      if (count != null) {
                        // 유효 범위 내에서만 상태 업데이트
                        if (count >= 2 && count <= 50) {
                          widget.onAction(
                            GroupSettingsAction.limitMemberCountChanged(count),
                          );
                        } else if (count < 2) {
                          _memberCountController.text = "2";
                          widget.onAction(
                            const GroupSettingsAction.limitMemberCountChanged(
                              2,
                            ),
                          );
                        } else if (count > 50) {
                          _memberCountController.text = "50";
                          widget.onAction(
                            const GroupSettingsAction.limitMemberCountChanged(
                              50,
                            ),
                          );
                        }
                      }
                      FocusScope.of(context).unfocus();
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      // onEditingComplete와 동일한 로직 수행
                      if (value.isEmpty) {
                        _memberCountController.text = "2";
                        widget.onAction(
                          const GroupSettingsAction.limitMemberCountChanged(2),
                        );
                        return;
                      }

                      final count = int.tryParse(value);
                      if (count != null) {
                        if (count >= 2 && count <= 50) {
                          widget.onAction(
                            GroupSettingsAction.limitMemberCountChanged(count),
                          );
                        } else if (count < 2) {
                          _memberCountController.text = "2";
                          widget.onAction(
                            const GroupSettingsAction.limitMemberCountChanged(
                              2,
                            ),
                          );
                        } else if (count > 50) {
                          _memberCountController.text = "50";
                          widget.onAction(
                            const GroupSettingsAction.limitMemberCountChanged(
                              50,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),

              // 인원수 증가 버튼
              _buildMemberCountButton(
                icon: Icons.add,
                onPressed:
                    widget.state.isEditing && widget.state.limitMemberCount < 50
                        ? () {
                          final newValue = widget.state.limitMemberCount + 1;
                          // 컨트롤러 업데이트 먼저
                          _memberCountController.text = newValue.toString();
                          // 그다음 상태 업데이트
                          widget.onAction(
                            GroupSettingsAction.limitMemberCountChanged(
                              newValue,
                            ),
                          );
                        }
                        : null,
              ),

              const SizedBox(width: 4),
              Text('명', style: AppTextStyles.body1Regular),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCountButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            onPressed != null
                ? AppColorStyles.primary100
                : AppColorStyles.gray60.withValues(alpha: 0.3),
        boxShadow:
            onPressed != null
                ? [
                  BoxShadow(
                    color: AppColorStyles.primary100.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  Widget _buildTagInputSection(bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '그룹 태그',
                style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 16),
              ),
              Text(
                '${widget.state.hashTags.length}/10',
                style: TextStyle(color: AppColorStyles.gray80, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              isEditing
                  ? TagInputField(
                    tags: widget.state.hashTags,
                    onAddTag:
                        (value) => widget.onAction(
                          GroupSettingsAction.hashTagAdded(value),
                        ),
                    onRemoveTag:
                        (value) => widget.onAction(
                          GroupSettingsAction.hashTagRemoved(value),
                        ),
                    hintText: '#태그를 입력 후 추가하세요',
                  )
                  : widget.state.hashTags.isEmpty
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        '등록된 태그가 없습니다',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                  : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        widget.state.hashTags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorStyles.primary60.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#${tag.content}',
                                  style: TextStyle(
                                    color: AppColorStyles.primary100,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.state.errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 소스 타입에 따라 적절한 이미지 위젯 생성
  Widget _buildImageBySourceType(String imageUrl) {
    // 에셋 이미지
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
    // 로컬 파일 이미지 (file:// 프로토콜)
    else if (imageUrl.startsWith('file://')) {
      return Image.file(
        File(imageUrl.replaceFirst('file://', '')),
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
    // 네트워크 이미지 (http:// 또는 https://)
    else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
    // 기타 경우 (Mock 테스트 이미지 등)
    else {
      return Image.network(
        'https://via.placeholder.com/160',
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
  }

  Widget _buildMemberList() {
    final group = widget.state.group.valueOrNull;
    final members = widget.state.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '멤버 목록',
            style: AppTextStyles.subtitle1Bold.copyWith(fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '참여 현황',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColorStyles.gray100,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary100.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group?.memberCount ?? 0}명 / ${widget.state.limitMemberCount}명',
                      style: TextStyle(
                        color: AppColorStyles.primary100,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // 멤버 목록 표시
              switch (members) {
                AsyncLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                AsyncError(:final error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '멤버 정보를 불러올 수 없습니다\n$error',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                AsyncData(:final value) =>
                  value.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '멤버가 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      )
                      : Column(
                        children:
                            value
                                .map((member) => _buildMemberItem(member))
                                .toList(),
                      ),
                _ => const SizedBox.shrink(), // Handle any other cases
              },
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(dynamic member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorStyles.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorStyles.gray40.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorStyles.primary100.withValues(alpha: 0.1),
            ),
            child:
                member.profileUrl?.isNotEmpty == true
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        member.profileUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: AppColorStyles.primary100,
                            size: 24,
                          );
                        },
                      ),
                    )
                    : Icon(
                      Icons.person,
                      color: AppColorStyles.primary100,
                      size: 24,
                    ),
          ),
          const SizedBox(width: 12),

          // 멤버 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.userName ?? '알 수 없음',
                      style: AppTextStyles.captionRegular.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (member.role == 'owner')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorStyles.primary100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '방장',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '가입일: ${_formatDate(member.joinedAt)}',
                  style: TextStyle(
                    color: AppColorStyles.gray80,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 활동 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  member.isActive == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColorStyles.gray40.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        member.isActive == true
                            ? Colors.green
                            : AppColorStyles.gray60,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  member.isActive == true ? '활성' : '비활성',
                  style: TextStyle(
                    color:
                        member.isActive == true
                            ? Colors.green[700]
                            : AppColorStyles.gray80,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '알 수 없음';
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }
}
