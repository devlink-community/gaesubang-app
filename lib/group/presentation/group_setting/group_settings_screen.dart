// lib/group/presentation/group_settings/group_settings_screen.dart
import 'dart:io';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_setting/group_settings_state.dart';
import 'package:devlink_mobile_app/group/presentation/labeled_text_field.dart';
import 'package:devlink_mobile_app/group/presentation/tag_input_field.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  }

  void _updateTextControllers() {
    _nameController.text = widget.state.name;
    _descriptionController.text = widget.state.description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.state.group is AsyncLoading || widget.state.isSubmitting;
    final isEditing = widget.state.isEditing;
    final isOwner = widget.state.isOwner; // 방장 여부

    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isLoading && isOwner)
            TextButton(
              onPressed: () {
                if (isEditing) {
                  widget.onAction(const GroupSettingsAction.save());
                } else {
                  widget.onAction(const GroupSettingsAction.toggleEditMode());
                }
              },
              child: Text(isEditing ? '저장' : '수정'),
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  widget.onAction(const GroupSettingsAction.refresh());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.state.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.state.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text('그룹 정보', style: AppTextStyles.subtitle1Bold),
                      const SizedBox(height: 16),

                      // 그룹 이미지
                      _buildGroupImage(),
                      const SizedBox(height: 24),

                      // 그룹 이름
                      LabeledTextField(
                        label: '그룹 이름',
                        hint: '그룹 이름을 입력하세요',
                        controller: _nameController,
                        onChanged:
                            (value) => widget.onAction(
                              GroupSettingsAction.nameChanged(value),
                            ),
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 20),

                      // 그룹 설명
                      LabeledTextField(
                        label: '그룹 설명',
                        hint: '그룹에 대한 설명을 입력하세요',
                        controller: _descriptionController,
                        maxLines: 3,
                        onChanged:
                            (value) => widget.onAction(
                              GroupSettingsAction.descriptionChanged(value),
                            ),
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 24),

                      // 멤버 제한
                      Text('멤버 제한', style: AppTextStyles.subtitle1Bold),
                      const SizedBox(height: 8),
                      _buildMemberLimitSlider(),
                      const SizedBox(height: 24),

                      // 태그
                      Text('태그', style: AppTextStyles.subtitle1Bold),
                      const SizedBox(height: 8),

                      if (isEditing)
                        TagInputField(
                          tags: widget.state.hashTags,
                          onAddTag:
                              (value) => widget.onAction(
                                GroupSettingsAction.hashTagAdded(value),
                              ),
                          onRemoveTag:
                              (value) => widget.onAction(
                                GroupSettingsAction.hashTagRemoved(value),
                              ),
                          hintText: '태그 입력 후 추가',
                        )
                      else
                        widget.state.hashTags.isEmpty
                            ? const Text(
                              '등록된 태그가 없습니다',
                              style: TextStyle(color: Colors.grey),
                            )
                            : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  widget.state.hashTags
                                      .map(
                                        (tag) => Chip(label: Text(tag.content)),
                                      )
                                      .toList(),
                            ),

                      const SizedBox(height: 32),

                      // 그룹 멤버 목록 (읽기 전용)
                      if (!isEditing) _buildMemberList(),

                      const SizedBox(height: 32),

                      // 그룹 탈퇴 버튼
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              () => widget.onAction(
                                const GroupSettingsAction.leaveGroup(),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('그룹 탈퇴'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildGroupImage() {
    return Center(
      child: GestureDetector(
        onTap:
            (widget.state.isEditing && widget.state.isOwner)
                ? () => widget.onAction(const GroupSettingsAction.selectImage())
                : null,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColorStyles.background,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: AppColorStyles.gray40),
              ),
              child:
                  widget.state.imageUrl == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.state.isEditing && widget.state.isOwner
                                ? Icons.add_photo_alternate_outlined
                                : Icons.group,
                            size: 40,
                            color: AppColorStyles.gray100,
                          ),
                          if (widget.state.isEditing && widget.state.isOwner)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '이미지 추가',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      )
                      : _buildGroupImageContent(widget.state.imageUrl!),
            ),
            if (widget.state.imageUrl != null &&
                widget.state.isEditing &&
                widget.state.isOwner)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    widget.onAction(
                      const GroupSettingsAction.imageUrlChanged(null),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColorStyles.primary100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColorStyles.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberLimitSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('최대 인원수'),
            Text(
              '${widget.state.limitMemberCount}명',
              style: AppTextStyles.subtitle1Bold.copyWith(
                color: AppColorStyles.primary100,
              ),
            ),
          ],
        ),
        Slider(
          value: widget.state.limitMemberCount.toDouble(),
          min: 2,
          max: 50,
          divisions: 48,
          label: widget.state.limitMemberCount.toString(),
          activeColor: AppColorStyles.primary100,
          inactiveColor: AppColorStyles.primary60.withOpacity(0.3),
          onChanged:
              widget.state.isEditing
                  ? (value) => widget.onAction(
                    GroupSettingsAction.limitMemberCountChanged(value.toInt()),
                  )
                  : null,
        ),
      ],
    );
  }

  // 이미지 표시 로직을 분리한 메서드
  Widget _buildGroupImageContent(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: _buildImageBySourceType(imageUrl),
    );
  }

  // 이미지 소스 타입에 따라 적절한 이미지 위젯 생성
  Widget _buildImageBySourceType(String imageUrl) {
    // 에셋 이미지
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 120,
        height: 120,
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
        width: 120,
        height: 120,
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
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
    // 기타 경우 (Mock 테스트 이미지 등)
    else {
      return Image.network(
        'https://via.placeholder.com/120',
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    }
  }

  Widget _buildMemberList() {
    final group = widget.state.group.valueOrNull;
    if (group == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('멤버 목록', style: AppTextStyles.subtitle1Bold),
            Text(
              '${group.members.length}명 / ${widget.state.limitMemberCount}명',
              style: TextStyle(
                color: AppColorStyles.primary100,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        group.members.isEmpty
            ? const Center(
              child: Text(
                '아직 멤버가 없습니다',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
            : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = group.members[index];
                final isOwner = member.id == group.owner.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isOwner
                            ? AppColorStyles.primary80
                            : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    child: Text(
                      member.nickname.isNotEmpty
                          ? member.nickname.substring(0, 1)
                          : '?',
                    ),
                  ),
                  title: Text(
                    member.nickname,
                    style: TextStyle(
                      fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    member.email,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing:
                      isOwner
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorStyles.primary60,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '방장',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                          : null,
                );
              },
            ),
      ],
    );
  }
}
