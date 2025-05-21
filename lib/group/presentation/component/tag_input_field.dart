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
    this.hintText = '태그를 입력하고 엔터 또는 추가를 누르세요',
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _tagCtrl = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void dispose() {
    _tagCtrl.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final value = _tagCtrl.text.trim();
    if (value.isNotEmpty) {
      // 이미 있는 태그인지 확인
      bool isDuplicate = widget.tags.any(
        (tag) => tag.content.toLowerCase() == value.toLowerCase(),
      );

      if (!isDuplicate) {
        widget.onAddTag(value);
        _tagCtrl.clear();
      } else {
        // 중복 태그 알림
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미 추가된 태그입니다')));
      }
    }
    _tagFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                focusNode: _tagFocusNode,
                style: AppTextStyles.body1Regular,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.body1Regular.copyWith(
                    color: AppColorStyles.gray60,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorStyles.gray40),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorStyles.gray40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColorStyles.primary100,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.tag, size: 20),
                ),
                // 엔터키로 태그 추가
                onSubmitted: (_) => _addTag(),
                // 엔터키 설정
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColorStyles.primary100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '추가',
                  style: AppTextStyles.button1Medium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorStyles.primary60.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${tag.content}',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColorStyles.primary100,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => widget.onRemoveTag(tag.content),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColorStyles.primary100.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 10,
                              color: AppColorStyles.primary100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}
