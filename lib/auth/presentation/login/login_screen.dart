// lib/auth/presentation/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login/login_state.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_text_field.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_button.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  final LoginState state;
  final void Function(LoginAction action) onAction;

  const LoginScreen({super.key, required this.state, required this.onAction});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 확인
    final loading = widget.state.loginUserResult?.isLoading ?? false;

    return Scaffold(
      body: SafeArea(
        // 키보드가 올라올 때 자동으로 화면 크기를 조정
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          // 레이아웃 구조 변경: 스크롤뷰와 버튼영역을 분리
          child: Column(
            children: [
              // 1. 스크롤 가능한 콘텐츠 영역 - Expanded로 확장
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // 로그인 타이틀
                      Text('로그인', style: AppTextStyles.heading2Bold),
                      // 회원가입 안내 텍스트
                      Row(
                        children: [
                          Text(
                            '계정이 없으신가요?',
                            style: AppTextStyles.body1Regular,
                          ),
                          TextButton(
                            onPressed:
                                () => widget.onAction(
                              const LoginAction.navigateToSignUp(),
                            ),
                            child: Text(
                              '회원가입',
                              style: AppTextStyles.body1Regular.copyWith(
                                color: AppColorStyles.primary100,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // 이메일 입력
                      CustomTextField(
                        label: '',
                        hintText: 'Email address',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => {},
                      ),
                      const SizedBox(height: 10),
                      // 비밀번호 입력
                      CustomTextField(
                        label: '',
                        hintText: 'Password',
                        controller: passwordController,
                        obscureText: true,
                        onChanged: (value) => {},
                      ),
                      // 비밀번호 찾기 링크
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              () => widget.onAction(
                            const LoginAction.navigateToForgetPassword(),
                          ),
                          child: Text(
                            '비밀번호를 잊어버리셨나요?',
                            style: AppTextStyles.body2Regular.copyWith(
                              color: AppColorStyles.gray80,
                            ),
                          ),
                        ),
                      ),

                      // 오류 메시지 UI 제거 (Snackbar로 대체)

                      // 추가 여백
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 2. 하단 버튼 영역 - 키보드와 상관없이 항상 화면 하단에 고정
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: CustomButton(
                  text: '로그인',
                  onPressed:
                      () => widget.onAction(
                    LoginAction.loginPressed(
                      email: emailController.text,
                      password: passwordController.text,
                    ),
                  ),
                  isLoading: loading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}