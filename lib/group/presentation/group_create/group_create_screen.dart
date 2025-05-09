// lib/group/presentation/group_create/group_create_screen.dart
import 'dart:io';

import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_state.dart';
import 'package:devlink_mobile_app/group/presentation/labeled_text_field.dart';
import 'package:devlink_mobile_app/group/presentation/tag_input_field.dart';
import 'package:flutter/material.dart';

class GroupCreateScreen extends StatefulWidget {
  final GroupCreateState state;
  final void Function(GroupCreateAction action) onAction;

  const GroupCreateScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.state.name;
    _descriptionController.text = widget.state.description;
  }

  @override
  void didUpdateWidget(covariant GroupCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.createdGroupId != null &&
        oldWidget.state.createdGroupId == null) {
      // 그룹 생성 완료 → 루트에서 처리할 것임
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    // _memberIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state.isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 생성'),
        actions: [
          TextButton(
            onPressed:
                isLoading
                    ? null
                    : () => widget.onAction(const GroupCreateAction.submit()),
            child: const Text('완료'),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기본정보', style: AppTextStyles.subtitle1Bold),
                    _buildThumbnailSelector(),
                    const SizedBox(height: 8),
                    LabeledTextField(
                      label: '그룹 이름',
                      hint: '그룹 이름을 입력하세요',
                      controller: _nameController,
                      onChanged:
                          (value) => widget.onAction(
                            GroupCreateAction.nameChanged(value),
                          ),
                    ),
                    const SizedBox(height: 16),
                    LabeledTextField(
                      label: '그룹 설명',
                      hint: '그룹에 대한 설명을 입력하세요',
                      controller: _descriptionController,
                      maxLines: 3,
                      onChanged:
                          (value) => widget.onAction(
                            GroupCreateAction.descriptionChanged(value),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text('멤버제한', style: AppTextStyles.subtitle1Bold),
                    const SizedBox(height: 8),
                    _buildMemberLimitSlider(),
                    const SizedBox(height: 24),
                    Text('태그추가', style: AppTextStyles.subtitle1Bold),
                    const SizedBox(height: 8),
                    TagInputField(
                      tags: widget.state.hashTags,
                      onAddTag:
                          (value) => widget.onAction(
                            GroupCreateAction.hashTagAdded(value),
                          ),
                      onRemoveTag:
                          (value) => widget.onAction(
                            GroupCreateAction.hashTagRemoved(value),
                          ),
                      hintText: '태그 입력 후 추가',
                    ),
                    const SizedBox(height: 24),
                    if (widget.state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildThumbnailSelector() {
    return Center(
      child: GestureDetector(
        onTap: () => widget.onAction(const GroupCreateAction.selectImage()),
        child: Stack(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColorStyles.background,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColorStyles.gray40),
              ),
              child:
                  widget.state.imageUrl == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: AppColorStyles.gray100,
                          ),
                        ],
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child:
                            widget.state.imageUrl!.startsWith('http')
                                ? Image.network(
                                  widget.state.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: 150,
                                  height: 150,
                                )
                                : Image.file(
                                  File(
                                    widget.state.imageUrl!.replaceFirst(
                                      'file://',
                                      '',
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                  width: 150,
                                  height: 150,
                                ),
                      ),
            ),
            if (widget.state.imageUrl != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    widget.onAction(
                      const GroupCreateAction.imageUrlChanged(null),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColorStyles.primary100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
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
          onChanged:
              (value) => widget.onAction(
                GroupCreateAction.limitMemberCountChanged(value.toInt()),
              ),
        ),
      ],
    );
  }
}
