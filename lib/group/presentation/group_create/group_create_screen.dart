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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state.isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('새 그룹 만들기', style: AppTextStyles.heading6Bold),
        actions: [
          TextButton(
            onPressed:
                isLoading
                    ? null
                    : () => widget.onAction(const GroupCreateAction.submit()),
            child: Text(
              '완료',
              style: TextStyle(
                color: isLoading ? Colors.grey : AppColorStyles.primary100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일 선택기
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap:
                                () => widget.onAction(
                                  const GroupCreateAction.selectImage(),
                                ),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColorStyles.primary100.withOpacity(
                                  0.05,
                                ),
                                border: Border.all(
                                  color: AppColorStyles.primary100.withOpacity(
                                    0.2,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child:
                                  widget.state.imageUrl == null
                                      ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo_camera_outlined,
                                            size: 36,
                                            color: AppColorStyles.primary100
                                                .withOpacity(0.8),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '프로필 이미지 추가',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColorStyles.primary100
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      )
                                      : ClipRRect(
                                        borderRadius: BorderRadius.circular(70),
                                        child:
                                            widget.state.imageUrl!.startsWith(
                                                  'http',
                                                )
                                                ? Image.network(
                                                  widget.state.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  width: 140,
                                                  height: 140,
                                                )
                                                : Image.file(
                                                  File(
                                                    widget.state.imageUrl!
                                                        .replaceFirst(
                                                          'file://',
                                                          '',
                                                        ),
                                                  ),
                                                  fit: BoxFit.cover,
                                                  width: 140,
                                                  height: 140,
                                                ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '그룹을 대표하는 이미지를 선택하세요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 그룹 이름
                    LabeledTextField(
                      label: '그룹 이름',
                      hint: '그룹 이름을 입력하세요',
                      controller: _nameController,
                      onChanged:
                          (value) => widget.onAction(
                            GroupCreateAction.nameChanged(value),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // 그룹 설명
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
                    const SizedBox(height: 32),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('멤버 제한', style: AppTextStyles.subtitle1Bold),
                        const SizedBox(height: 16),

                        // 세련된 슬라이더
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 8,
                            activeTrackColor: AppColorStyles.primary100,
                            inactiveTrackColor: Colors.grey[200],
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                              elevation: 4,
                            ),
                            overlayColor: AppColorStyles.primary100.withOpacity(
                              0.2,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 24,
                            ),
                          ),
                          child: Slider(
                            value: widget.state.limitMemberCount.toDouble(),
                            min: 2,
                            max: 50,
                            divisions: 48,
                            onChanged:
                                (value) => widget.onAction(
                                  GroupCreateAction.limitMemberCountChanged(
                                    value.toInt(),
                                  ),
                                ),
                          ),
                        ),

                        // 최소/최대 표시 라벨
                        const SizedBox(height: 16),

                        // 최대 인원수 입력 필드
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('최대 인원수', style: AppTextStyles.body1Regular),
                            const SizedBox(width: 12),

                            // 인원수 입력 필드
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColorStyles.gray40,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColorStyles.gray40,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColorStyles.primary100,
                                    ),
                                  ),
                                  isDense: true,
                                ),
                                initialValue:
                                    widget.state.limitMemberCount.toString(),
                                onChanged: (value) {
                                  final count = int.tryParse(value);
                                  if (count != null &&
                                      count >= 2 &&
                                      count <= 50) {
                                    widget.onAction(
                                      GroupCreateAction.limitMemberCountChanged(
                                        count,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('명', style: AppTextStyles.body1Regular),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 태그 입력 영역
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 에러 메시지
                    if (widget.state.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.state.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
