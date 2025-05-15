// lib/auth/presentation/signup/signup_screen.dart

import 'package:devlink_mobile_app/auth/presentation/component/custom_button.dart';
import 'package:devlink_mobile_app/auth/presentation/component/custom_text_field.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_action.dart';
import 'package:devlink_mobile_app/auth/presentation/signup/signup_state.dart';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignupScreen extends StatefulWidget {
  final SignupState state;
  final void Function(SignupAction action) onAction;

  const SignupScreen({super.key, required this.state, required this.onAction});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _passwordConfirmFocusNode = FocusNode();

  // ScrollController 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기값 설정
    _nicknameController.text = widget.state.nickname;
    _emailController.text = widget.state.email;
    _passwordController.text = widget.state.password;
    _passwordConfirmController.text = widget.state.passwordConfirm;

    // 포커스 리스너 설정
    _nicknameFocusNode.addListener(_onNicknameFocusChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
    _passwordFocusNode.addListener(_onPasswordFocusChanged);
    _passwordConfirmFocusNode.addListener(_onPasswordConfirmFocusChanged);

    // 각 포커스 노드에 리스너 추가하여 포커스 시 스크롤 조정
    _nicknameFocusNode.addListener(() {
      if (_nicknameFocusNode.hasFocus) {
        _scrollToFocusedField(_nicknameFocusNode);
      }
    });

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _scrollToFocusedField(_emailFocusNode);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _scrollToFocusedField(_passwordFocusNode);
      }
    });

    _passwordConfirmFocusNode.addListener(() {
      if (_passwordConfirmFocusNode.hasFocus) {
        _scrollToFocusedField(_passwordConfirmFocusNode);
      }
    });
  }

  // 포커스된 필드로 스크롤하는 메서드
  void _scrollToFocusedField(FocusNode focusNode) {
    // 키보드가 올라오는데 약간의 딜레이가 있으므로 짧은 딜레이 후 스크롤
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final RenderObject? object = focusNode.context?.findRenderObject();
      if (object == null) return;

      final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);

      // 스크롤 위치 계산 - 필드가 화면 중간쯤에 위치하도록 조정
      final double offset = _calculateScrollOffset(object, viewport);

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 스크롤 위치 계산 - 포커스된 필드가 키보드 위에 적절히 위치하도록
  double _calculateScrollOffset(
    RenderObject object,
    RenderAbstractViewport viewport,
  ) {
    // 현재 필드의 뷰포트 내 위치 구하기
    final double position = viewport.getOffsetToReveal(object, 0.2).offset;

    // 추가 여백을 둬서 필드가 화면 상단에 너무 붙지 않게 함
    return position - 20; // 20픽셀 여백 추가
  }

  @override
  void didUpdateWidget(covariant SignupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 컨트롤러 값 동기화 - 필요한 경우에만 업데이트
    if (widget.state.nickname != _nicknameController.text) {
      _nicknameController.text = widget.state.nickname;
    }
    if (widget.state.email != _emailController.text) {
      _emailController.text = widget.state.email;
    }
    if (widget.state.password != _passwordController.text) {
      _passwordController.text = widget.state.password;
    }
    if (widget.state.passwordConfirm != _passwordConfirmController.text) {
      _passwordConfirmController.text = widget.state.passwordConfirm;
    }
  }

  @override
  void dispose() {
    // 컨트롤러 정리
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

    // 포커스 리스너 정리
    _nicknameFocusNode.removeListener(_onNicknameFocusChanged);
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _passwordFocusNode.removeListener(_onPasswordFocusChanged);
    _passwordConfirmFocusNode.removeListener(_onPasswordConfirmFocusChanged);

    // 포커스 노드 정리
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();

    // 스크롤 컨트롤러 정리
    _scrollController.dispose();

    super.dispose();
  }

  // 포커스 변경 리스너
  void _onNicknameFocusChanged() {
    // 포커스를 잃을 때 유효성 검사 및 중복 확인 명시적 호출
    if (!_nicknameFocusNode.hasFocus && _nicknameController.text.isNotEmpty) {
      widget.onAction(SignupAction.nicknameFocusChanged(false));
      // 추가: 명시적으로 중복 확인 액션 호출
      widget.onAction(const SignupAction.checkNicknameAvailability());
    }
  }

  void _onEmailFocusChanged() {
    // 포커스를 잃을 때 유효성 검사 및 중복 확인 명시적 호출
    if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
      widget.onAction(SignupAction.emailFocusChanged(false));
      // 추가: 명시적으로 중복 확인 액션 호출
      widget.onAction(const SignupAction.checkEmailAvailability());
    }
  }

  void _onPasswordFocusChanged() {
    if (!_passwordFocusNode.hasFocus) {
      widget.onAction(SignupAction.passwordFocusChanged(false));
    }
  }

  void _onPasswordConfirmFocusChanged() {
    if (!_passwordConfirmFocusNode.hasFocus) {
      widget.onAction(SignupAction.passwordConfirmFocusChanged(false));
    }
  }

  // 다음 필드로 포커스 이동하는 함수
  void _fieldFocusChange(
    BuildContext context,
    FocusNode currentFocus,
    FocusNode nextFocus,
  ) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 상태 확인
    final isLoading = widget.state.signupResult?.isLoading ?? false;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // 배경 터치 시 키보드 내리기
          // 레이아웃 구조 변경: 스크롤 영역과 버튼 영역 분리
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 스크롤 가능한 콘텐츠 영역 - Expanded로 확장
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, // 스크롤 컨트롤러 설정
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // 회원가입 타이틀
                        Text('회원가입', style: AppTextStyles.heading2Bold),

                        // 로그인 링크
                        Row(
                          children: [
                            Text(
                              '계정이 있으신가요?',
                              style: AppTextStyles.body1Regular,
                            ),
                            TextButton(
                              onPressed:
                                  () => widget.onAction(
                                    const SignupAction.navigateToLogin(),
                                  ),
                              child: Text(
                                '로그인',
                                style: AppTextStyles.body1Regular.copyWith(
                                  color: AppColorStyles.primary100,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // 입력 필드 섹션 - 간격 일정하게 유지
                        _buildInputFields(context),

                        // 이용약관 동의 섹션
                        _buildTermsAgreement(),

                        // 스크롤 영역 하단 여백
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 2. 하단 버튼 영역 - 키보드가 나타나도 항상 보이는 영역
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CustomButton(
                    text: '회원가입',
                    onPressed:
                        () => widget.onAction(const SignupAction.submit()),
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 입력 필드 섹션 - 모듈화하여 가독성 향상
  Widget _buildInputFields(BuildContext context) {
    return Column(
      children: [
        // 닉네임 입력
        CustomTextField(
          label: '',
          hintText: 'nick name',
          controller: _nicknameController,
          focusNode: _nicknameFocusNode,
          errorText: widget.state.nicknameError,
          successText: widget.state.nicknameSuccess, // 성공 메시지 추가
          onChanged:
              (value) => widget.onAction(SignupAction.nicknameChanged(value)),
          // 닉네임 입력 후 완료 버튼 누르면 이메일 필드로 포커스 이동
          onFieldSubmitted:
              (_) => _fieldFocusChange(
                context,
                _nicknameFocusNode,
                _emailFocusNode,
              ),
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 10),

        // 이메일 입력
        CustomTextField(
          label: '',
          hintText: 'Email address',
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          errorText: widget.state.emailError,
          successText: widget.state.emailSuccess, // 성공 메시지 추가
          onChanged:
              (value) => widget.onAction(SignupAction.emailChanged(value)),
          // 이메일 입력 후 완료 버튼 누르면 비밀번호 필드로 포커스 이동
          onFieldSubmitted:
              (_) => _fieldFocusChange(
                context,
                _emailFocusNode,
                _passwordFocusNode,
              ),
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 10),

        // 비밀번호 입력
        CustomTextField(
          label: '',
          hintText: 'Password',
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: true,
          errorText: widget.state.passwordError,
          onChanged:
              (value) => widget.onAction(SignupAction.passwordChanged(value)),
          // 비밀번호 입력 후 완료 버튼 누르면 비밀번호 확인 필드로 포커스 이동
          onFieldSubmitted:
              (_) => _fieldFocusChange(
                context,
                _passwordFocusNode,
                _passwordConfirmFocusNode,
              ),
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 10),

        // 비밀번호 확인 입력
        CustomTextField(
          label: '',
          hintText: 'Password confirm',
          controller: _passwordConfirmController,
          focusNode: _passwordConfirmFocusNode,
          obscureText: true,
          errorText: widget.state.passwordConfirmError,
          onChanged:
              (value) =>
                  widget.onAction(SignupAction.passwordConfirmChanged(value)),
          // 완료 버튼을 누르면 키보드 감추기
          onFieldSubmitted: (_) {
            _passwordConfirmFocusNode.unfocus();
          },
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  // 이용약관 동의 섹션 - 모듈화하여 가독성 향상
  Widget _buildTermsAgreement() {
    return Column(
      children: [
        // 이용약관 동의 (우측 정렬)
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
          children: [
            Checkbox(
              value: widget.state.agreeToTerms,
              onChanged:
                  widget.state.isTermsAgreed
                      ? null // 약관에 이미 동의했으면 비활성화
                      : (value) => widget.onAction(
                        SignupAction.agreeToTermsChanged(value ?? false),
                      ),
              activeColor: AppColorStyles.primary100,
              // 비활성화 상태에서도 색상 유지
              fillColor:
                  widget.state.isTermsAgreed
                      ? WidgetStateProperty.all(AppColorStyles.gray60)
                      : null,
            ),
            GestureDetector(
              onTap:
                  () => widget.onAction(const SignupAction.navigateToTerms()),
              child: Text(
                '회원가입 약관 보시겠어요?',
                style: AppTextStyles.body2Regular.copyWith(
                  color: AppColorStyles.gray80,
                ),
              ),
            ),
          ],
        ),

        // 약관 동의 에러 메시지 - 고정 높이로 일관성 유지
        Container(
          height: 24, // 에러 메시지 영역 고정 높이
          padding: const EdgeInsets.only(right: 16.0),
          alignment: Alignment.centerRight, // 에러 메시지도 우측 정렬
          child:
              widget.state.termsError != null
                  ? Text(
                    widget.state.termsError!,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColorStyles.error,
                    ),
                  )
                  : null,
        ),
      ],
    );
  }
}
