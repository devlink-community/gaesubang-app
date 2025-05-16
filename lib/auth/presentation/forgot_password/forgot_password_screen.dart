// lib/auth/presentation/forgot_password/forgot_password_screen.dart
import 'package:devlink_mobile_app/auth/presentation/component/custom_button.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_text_field.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_action.dart';
import 'package:devlink_mobile_app/auth/presentation/forgot_password/forgot_password_state.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final ForgotPasswordState state;
  final void Function(ForgotPasswordAction action) onAction;

  const ForgotPasswordScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  late final FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.state.email);
    _emailFocusNode = FocusNode()..addListener(_onEmailFocusChanged);
  }

  void _onEmailFocusChanged() {
    widget.onAction(
      ForgotPasswordAction.emailFocusChanged(_emailFocusNode.hasFocus),
    );
  }

  @override
  void didUpdateWidget(covariant ForgotPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.email != _emailController.text) {
      _emailController.text = widget.state.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 확인
    final isLoading = widget.state.resetPasswordResult?.isLoading ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // 배경 터치시 키보드 내림
          // 전체 레이아웃을 Column으로 변경하여 버튼 영역 분리
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                // 1. 스크롤 가능한 콘텐츠 영역 - Expanded로 확장
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // 제목
                        Text(
                          '비밀번호 재설정',
                          style: AppTextStyles.heading2Bold.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // 안내 텍스트
                        Text(
                          '입력하신 이메일로 비밀번호를 재설정할 수 있는\n링크를 전송합니다. 이메일을 작성해주세요.',
                          style: AppTextStyles.body1Regular.copyWith(
                            color: AppColorStyles.gray100,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // 이메일 입력 필드
                        CustomTextField(
                          label: '',
                          hintText: 'Email address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: widget.state.emailError,
                          onChanged:
                              (value) => widget.onAction(
                            ForgotPasswordAction.emailChanged(value),
                          ),
                          focusNode: _emailFocusNode,
                          // 필드 완료 시 추가 동작
                          onFieldSubmitted: (_) {
                            _emailFocusNode.unfocus();
                            // 선택적: 여기서 이메일 발송 액션 호출 가능
                            // widget.onAction(ForgotPasswordAction.sendResetEmail());
                          },
                          textInputAction: TextInputAction.done,
                        ),

                        const SizedBox(height: 24),

                        // 통합 오류 메시지 표시
                        if (widget.state.formErrorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(top: 0, bottom: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColorStyles.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColorStyles.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColorStyles.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.state.formErrorMessage!,
                                    style: AppTextStyles.body2Regular.copyWith(
                                      color: AppColorStyles.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 성공 메시지 표시 (이미 전송된 경우)
                        if (widget.state.successMessage != null &&
                            widget.state.resetPasswordResult?.hasValue == true)
                          Container(
                            margin: const EdgeInsets.only(top: 0, bottom: 24),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColorStyles.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColorStyles.success.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColorStyles.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.state.successMessage!,
                                    style: AppTextStyles.body2Regular.copyWith(
                                      color: AppColorStyles.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 콘텐츠 영역 아래 추가 여백
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // 2. 하단 버튼 영역 - 키보드가 나타나도 항상 보이는 영역
                Column(
                  children: [
                    // 이메일 발송하기 버튼
                    CustomButton(
                      text: '이메일 발송하기',
                      onPressed:
                          () => widget.onAction(
                        ForgotPasswordAction.sendResetEmail(),
                      ),
                      isLoading: isLoading,
                      backgroundColor: AppColorStyles.primary100,
                      foregroundColor: Colors.white,
                      height: 50,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 5),

                    // 로그인으로 돌아가기 텍스트 버튼
                    TextButton(
                      onPressed:
                          () => widget.onAction(
                        ForgotPasswordAction.navigateToLogin(),
                      ),
                      child: Text(
                        '로그인으로 돌아가기',
                        style: AppTextStyles.body2Regular.copyWith(
                          color: AppColorStyles.gray100,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    // 바닥 여백
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}