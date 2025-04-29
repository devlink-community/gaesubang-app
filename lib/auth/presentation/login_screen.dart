import 'package:devlink_mobile_app/auth/presentation/login_action.dart';
import 'package:devlink_mobile_app/auth/presentation/login_state.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: emailController),
          TextField(controller: passwordController, obscureText: true),
          ElevatedButton(
            onPressed:
                () => widget.onAction(
                  LoginAction.loginPressed(
                    email: emailController.text,
                    password: passwordController.text,
                  ),
                ),
            child: const Text('로그인'),
          ),
          TextButton(
            onPressed:
                () => widget.onAction(
                  const LoginAction.navigateToForgetPassword(),
                ),
            child: const Text('비밀번호를 잊으셨나요?'),
          ),
          TextButton(
            onPressed:
                () => widget.onAction(const LoginAction.navigateToSignUp()),
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }
}
