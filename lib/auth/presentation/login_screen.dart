import 'package:devlink_mobile_app/auth/presentation/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login_state.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final LoginState state;
  final void Function(LoginAction action) onAction;

  const LoginScreen({super.key, required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: passwordController, obscureText: true),
          ElevatedButton(
            onPressed:
                () => onAction(
                  LoginAction.loginPressed(
                    email: emailController.text,
                    password: passwordController.text,
                  ),
                ),
            child: const Text('로그인'),
          ),
          TextButton(
            onPressed:
                () => onAction(const LoginAction.navigateToForgetPassword()),
            child: const Text('비밀번호를 잊으셨나요?'),
          ),
          TextButton(
            onPressed: () => onAction(const LoginAction.navigateToSignUp()),
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }
}
