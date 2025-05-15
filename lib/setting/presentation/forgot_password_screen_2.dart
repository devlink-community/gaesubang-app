import 'package:flutter/material.dart';

import '../../auth/presentation/component/custom_button.dart';
import '../../auth/presentation/component/custom_text_field.dart';
import '../../auth/presentation/forgot_password/forgot_password_action.dart';

import '../../auth/presentation/forgot_password/forgot_password_state.dart';
import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';

class ForgotPasswordScreen2 extends StatefulWidget {
  final ForgotPasswordState state;
  final void Function(ForgotPasswordAction action) onAction;

  const ForgotPasswordScreen2({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<ForgotPasswordScreen2> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen2> {
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
  void didUpdateWidget(covariant ForgotPasswordScreen2 oldWidget) {
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
      appBar: AppBar(automaticallyImplyLeading: true),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 배경 터치시 키보드 내림
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              // 화면 높이만큼 최소 높이 설정
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                // mainAxisAlignment를 제거하고 Column으로 구성
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

                  // 이메일 입력 필드 - CustomTextField 활용
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
                  ),

                  // 여기에 Spacer 대신 조절 가능한 SizedBox 추가
                  // 이 높이를 조절하여 입력란과 버튼 사이 간격 조정 가능
                  SizedBox(height: MediaQuery.of(context).size.height * 0.364),

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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
