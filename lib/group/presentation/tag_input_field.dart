// lib/shared/components/tag_input_field.dart
import 'package:devlink_mobile_app/community/domain/model/hash_tag.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class TagInputField extends StatefulWidget {
  final List<HashTag> tags;
  final Function(String) onAddTag;
  final Function(String) onRemoveTag;
  final String hintText;

  const TagInputField({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    this.hintText = '태그 입력 후 추가',
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final value = _tagController.text.trim();
    if (value.isNotEmpty) {
      // 중복 태그 확인
      bool isDuplicate = widget.tags.any(
        (tag) => tag.content.toLowerCase() == value.toLowerCase(),
      );
      if (isDuplicate) {
        // 중복 태그가 있으면 사용자에게 알림 (옵션)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미 추가된 태그입니다.')));
        _tagController.clear();
        return;
      }
      widget.onAddTag(value);
      _tagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태에 따른 테두리 색상 설정
    Color borderColor = AppColorStyles.gray40; // 기본 색상은 그레이

    if (_hasFocus) {
      // 포커스 상태
      borderColor = AppColorStyles.primary100;
    } else if (_tagController.text.isNotEmpty) {
      // 입력값이 있는 상태
      borderColor = AppColorStyles.gray80;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 태그 입력 필드
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray60,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColorStyles.primary100),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (value) {
                  _addTag();
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorStyles.primary100,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '추가',
                style: AppTextStyles.button1Medium.copyWith(
                  color: AppColorStyles.white,
                ),
              ),
            ),
          ],
        ),

        // 태그 리스트 표시
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.tags.map((tag) {
                    return Chip(
                      label: Text(tag.content),
                      labelStyle: AppTextStyles.body2Regular,
                      backgroundColor: AppColorStyles.gray40.withOpacity(0.3),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => widget.onRemoveTag(tag.content),
                      deleteIconColor: AppColorStyles.gray80,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColorStyles.gray40),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}
