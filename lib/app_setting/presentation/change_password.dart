import 'package:flutter/material.dart';

import '../../auth/presentation/component/custom_button.dart';
import '../../auth/presentation/component/custom_text_field.dart';
import '../../core/styles/app_color_styles.dart';
import '../../core/styles/app_text_styles.dart';
import 'change_password_action.dart';
import 'change_password_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ChangePasswordState state;
  final void Function(ChangePasswordAction action) onAction;

  const ChangePasswordScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
      ChangePasswordAction.emailFocusChanged(_emailFocusNode.hasFocus),
    );
  }

  @override
  void didUpdateWidget(covariant ChangePasswordScreen oldWidget) {
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
    final isLoading = widget.state.resetPasswordResult?.isLoading ?? false;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('비밀번호 변경', style: AppTextStyles.heading6Bold),
        // Navigator key 충돌 방지를 위해 leading 직접 구현
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onAction(ChangePasswordAction.navigateBack()),
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      Text(
                        '비밀번호를 변경하시려면\n등록된 이메일 주소를 입력해주세요.',
                        style: AppTextStyles.body1Regular.copyWith(
                          color: AppColorStyles.gray100,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      CustomTextField(
                        label: '이메일',
                        hintText: 'Email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: widget.state.emailError,
                        onChanged:
                            (value) => widget.onAction(
                              ChangePasswordAction.emailChanged(value),
                            ),
                        focusNode: _emailFocusNode,
                        onFieldSubmitted: (_) {
                          _emailFocusNode.unfocus();
                        },
                        textInputAction: TextInputAction.done,
                      ),

                      const SizedBox(height: 24),
                      Column(
                        children: [
                          CustomButton(
                            text: '비밀번호 재설정 이메일 발송',
                            onPressed:
                                () => widget.onAction(
                                  ChangePasswordAction.sendResetEmail(),
                                ),
                            isLoading: isLoading,
                            backgroundColor: AppColorStyles.primary100,
                            foregroundColor: Colors.white,
                            height: 52,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
