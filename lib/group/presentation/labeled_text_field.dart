import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? errorText;
  final FocusNode? focusNode;
  final bool enabled;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.errorText,
    this.focusNode,
    this.enabled = true,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상태에 따른 테두리 색상 설정
    Color borderColor = AppColorStyles.gray40; // 기본 색상은 그레이

    if (widget.errorText != null) {
      // 에러 상태
      borderColor = AppColorStyles.error;
    } else if (_hasFocus) {
      // 포커스 상태
      borderColor = AppColorStyles.primary100;
    } else if (widget.controller.text.isNotEmpty) {
      // 입력값이 있는 상태
      borderColor = AppColorStyles.gray100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.body1Regular),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onSubmitted: widget.onFieldSubmitted,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColorStyles.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColorStyles.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIcon: widget.suffix,
          ),
        ),
      ],
    );
  }
}
