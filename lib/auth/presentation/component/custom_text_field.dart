import 'package:flutter/material.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';

/// 커스텀 텍스트 필드 컴포넌트
///
/// 기본, 포커스, 입력, 에러 상태를 지원합니다.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.controller,
    this.onChanged,
  });

  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 텍스트 필드 상태에 따른 테두리 색상 결정
    Color borderColor = AppColorStyles.gray40; // 기본 상태

    // 에러 상태
    if (widget.errorText != null) {
      borderColor = AppColorStyles.error;
    }
    // 포커스 상태
    else if (_hasFocus) {
      borderColor = AppColorStyles.primary100; // 보라색 (포커스)
    }
    // 입력 상태 (텍스트가 있고 포커스가 없는 경우)
    else if (widget.controller != null &&
        widget.controller!.text.isNotEmpty) {
      borderColor = AppColorStyles.gray80;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: AppTextStyles.body1Regular,
            ),
          ),

        // 텍스트 필드
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: AppTextStyles.body1Regular,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: widget.hintText,
              hintStyle: AppTextStyles.body1Regular.copyWith(
                color: AppColorStyles.gray60,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),

        // 에러 메시지
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColorStyles.error,
              ),
            ),
          ),
      ],
    );
  }
}