// lib/auth/presentation/component/custom_text_field.dart
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
    this.successText, // 성공 메시지 추가
    this.controller,
    this.onChanged,
    this.focusNode,
    // 새로 추가된 속성
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final String? successText; // 성공 메시지 추가
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  // 새로 추가된 속성
  final Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscureText = false; // 비밀번호 보기/숨기기 상태 변수 추가

  @override
  void initState() {
    super.initState();
    // 상위 위젯에서 제공한 focusNode가 있으면 사용하고, 없으면 새로 생성
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });

    // 초기 obscureText 상태 설정
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    // 내부에서 생성한 focusNode만 dispose
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
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
    else if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      borderColor = AppColorStyles.gray80;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(widget.label, style: AppTextStyles.body1Regular),
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
            obscureText: _obscureText, // 동적으로 변경되는 _obscureText 사용
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            // 새로 추가된 속성 설정
            onSubmitted: widget.onFieldSubmitted,
            textInputAction: widget.textInputAction,
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
              // 비밀번호 입력창인 경우만 보기/숨기기 아이콘 추가
              suffixIcon:
                  widget.obscureText
                      ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColorStyles.gray80,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText; // 보기/숨기기 상태 토글
                          });
                        },
                      )
                      : null,
            ),
          ),
        ),

        // 에러/성공 메시지 영역 - 고정 높이로 유지
        Container(
          height: 24, // 메시지 영역의 고정 높이
          padding: const EdgeInsets.only(top: 4.0, left: 4.0),
          alignment: Alignment.centerLeft,
          child:
              widget.errorText != null
                  ? Text(
                    widget.errorText!,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.error,
                    ),
                  )
                  // 성공 메시지가 있으면 녹색으로 표시
                  : widget.successText != null
                  ? Text(
                    widget.successText!,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.success,
                    ),
                  )
                  : null, // 에러나 성공 메시지가 없을 때는 빈 공간으로 유지
        ),
      ],
    );
  }
}
