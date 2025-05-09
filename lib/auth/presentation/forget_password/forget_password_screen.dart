// lib/auth/presentation/forget_password/forget_password_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forget_password/forget_password_state.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_text_field.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_button.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';

class ForgetPasswordScreen extends StatefulWidget {
  final ForgetPasswordState state;
  final void Function(ForgetPasswordAction action) onAction;

  const ForgetPasswordScreen({
    super.key,
    required this.state,
    required this.onAction
  });

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.state.email);
  }

  @override
  void didUpdateWidget(covariant ForgetPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 상태가 변경되면 컨트롤러 값 업데이트
    if (widget.state.email != emailController.text) {
      emailController.text = widget.state.email;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 확인
    final isLoading = widget.state.resetPasswordResult?.isLoading ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onAction(const ForgetPasswordAction.navigateToLogin()),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 배경 터치 시 키보드 내리기
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 안내 메시지
              Text(
                '비밀번호를 잊으셨나요?',
                style: AppTextStyles.heading2Bold,
              ),
              const SizedBox(height: 12),
              Text(
                '가입 시 등록한 이메일 주소를 입력하시면,\n비밀번호 재설정 링크를 보내드립니다.',
                style: AppTextStyles.body1Regular,
              ),
              const SizedBox(height: 40),

              // 이메일 입력
              CustomTextField(
                label: '이메일',
                hintText: '이메일 주소를 입력하세요',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: widget.state.emailError,
                onChanged: (value) => widget.onAction(ForgetPasswordAction.emailChanged(value)),
              ),

              const SizedBox(height: 24),

              // 성공 메시지 표시
              if (widget.state.successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorStyles.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.state.successMessage!,
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.success,
                    ),
                  ),
                ),

              // 에러 메시지 표시 부분
              if (widget.state.resetPasswordResult case AsyncError(:final error))
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppColorStyles.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '이메일 발송 실패: $error',
                    style: AppTextStyles.body2Regular.copyWith(
                      color: AppColorStyles.error,
                    ),
                  ),
                ),

              const Spacer(),

              // 이메일 발송 버튼
              CustomButton(
                text: '비밀번호 재설정 이메일 발송',
                onPressed: () => widget.onAction(const ForgetPasswordAction.submit()),
                isLoading: isLoading,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}