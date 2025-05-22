// lib/onboarding/presentation/onboarding_screen.dart
import 'dart:math' as math;
import 'package:devlink_mobile_app/onboarding/domain/model/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_action.dart';
import 'package:devlink_mobile_app/onboarding/presentation/onboarding_state.dart';

class OnboardingScreen extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final OnboardingState state;
  final Function(OnboardingAction action) onAction;

  const OnboardingScreen({
    super.key,
    required this.pages,
    required this.state,
    required this.onAction,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _backgroundAnimController;
  late AnimationController _contentAnimController;
  late AnimationController _floatingObjController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // 부유 객체 애니메이션
  late Animation<double> _float1Animation;
  late Animation<double> _float2Animation;
  late Animation<double> _float3Animation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.state.currentPage);

    // 배경 애니메이션 컨트롤러
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 콘텐츠 애니메이션 컨트롤러
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 부유 객체 애니메이션 컨트롤러
    _floatingObjController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    // 애니메이션들
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 부유 객체 애니메이션
    _float1Animation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatingObjController, curve: Curves.easeInOut),
    );

    _float2Animation = Tween<double>(begin: 8, end: -8).animate(
      CurvedAnimation(parent: _floatingObjController, curve: Curves.easeInOut),
    );

    _float3Animation = Tween<double>(begin: 3, end: -3).animate(
      CurvedAnimation(parent: _floatingObjController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _floatingObjController, curve: Curves.easeInOut),
    );

    // 초기 애니메이션 실행
    _backgroundAnimController.forward();
    _contentAnimController.forward();
    _floatingObjController.forward();
  }

  @override
  void didUpdateWidget(OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 페이지가 변경되면 애니메이션 재실행
    if (oldWidget.state.currentPage != widget.state.currentPage) {
      // 현재 페이지를 변경하고 애니메이션 실행
      _pageController.animateToPage(
        widget.state.currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );

      // 콘텐츠 애니메이션 재설정 및 실행
      _contentAnimController.reset();
      _contentAnimController.forward();

      // 배경 애니메이션 재실행
      _backgroundAnimController.reset();
      _backgroundAnimController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimController.dispose();
    _contentAnimController.dispose();
    _floatingObjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _contentAnimController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  if (widget.state.currentPage < widget.pages.length - 1)
                    TextButton(
                      onPressed: () {
                        widget.onAction(
                          const OnboardingAction.completeOnboarding(),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // 배경 그라데이션 (애니메이션)
          AnimatedBuilder(
            animation: _backgroundAnimController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.pages[widget.state.currentPage].backgroundColor,
                      _getDarkerColor(
                        widget.pages[widget.state.currentPage].backgroundColor,
                      ),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // 애니메이션 배경 요소들
          _buildAnimatedBackgroundObjects(),

          // 페이지 컨텐츠
          PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (index) {
              widget.onAction(OnboardingAction.goToPage(index));
            },
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              return _buildPage(page, index);
            },
          ),

          // 하단 네비게이션과 버튼 영역
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 50, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _getDarkerColor(
                      widget.pages[widget.state.currentPage].backgroundColor,
                    ).withValues(alpha: 0.9),
                    _getDarkerColor(
                      widget.pages[widget.state.currentPage].backgroundColor,
                    ).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _buildBottomButton(),
                  ),
                  const SizedBox(height: 24),
                  // 페이지 인디케이터
                  _buildPageIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackgroundObjects() {
    return AnimatedBuilder(
      animation: _floatingObjController,
      builder: (context, child) {
        return Stack(
          children: [
            // 좌측 상단 큰 원
            Positioned(
              top: -80 + _float1Animation.value * 10,
              left: -100 + _float2Animation.value * 8,
              child: Transform.rotate(
                angle: 0.2 + _rotateAnimation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(125),
                  ),
                ),
              ),
            ),

            // 우측 중간 작은 원
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.35 +
                  _float3Animation.value * 15,
              right: -30 + _float1Animation.value * 5,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),

            // 좌측 하단 중간 원
            Positioned(
              bottom: -50 + _float2Animation.value * 10,
              left: -30 + _float3Animation.value * 8,
              child: Transform.rotate(
                angle: -0.1 + _rotateAnimation.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
            ),

            // 우측 상단 작은 원
            Positioned(
              top: 100 + _float3Animation.value * 8,
              right: 40 + _float1Animation.value * 5,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            // 중앙 하단 가로선
            Positioned(
              bottom:
                  MediaQuery.of(context).size.height * 0.25 +
                  _float2Animation.value * 3,
              left: -100,
              child: Transform.rotate(
                angle: 0.1 + _rotateAnimation.value,
                child: Container(
                  width: MediaQuery.of(context).size.width + 200,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage(OnboardingPageModel page, int index) {
    return AnimatedBuilder(
      animation: _contentAnimController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // 일러스트레이션 영역
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: _buildIllustration(page, index),
                      ),

                      // const Spacer(),
                      const SizedBox(height: 20),

                      // 제목
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds);
                        },
                        child: Text(
                          page.title,
                          style: AppTextStyles.heading1Bold.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 설명
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          page.description,
                          style: AppTextStyles.subtitle1Medium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 일러스트레이션을 페이지별로 다르게 처리
  Widget _buildIllustration(OnboardingPageModel page, int index) {
    return AnimatedBuilder(
      animation: _floatingObjController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _float1Animation.value * 2,
            _float2Animation.value * 2,
          ),
          child: Hero(
            tag: 'onboarding-illustration-$index',
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  radius: 0.8,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 중심 그라데이션 원
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // 아이콘
                  Icon(page.icon, size: 100, color: Colors.white),

                  // 장식 원들
                  Positioned(
                    top: 40 + _float3Animation.value * 3,
                    right: 60 + _float1Animation.value * 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 50 + _float2Animation.value * 3,
                    left: 30 + _float3Animation.value * 2,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // 장식 선
                  Positioned(
                    bottom: 80,
                    right: 30,
                    child: Transform.rotate(
                      angle: math.pi / 4 + _rotateAnimation.value,
                      child: Container(
                        width: 40,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    // 페이지 인디케이터 최적화
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.pages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: 6,
            width: widget.state.currentPage == index ? 20 : 6,
            decoration: BoxDecoration(
              color:
                  widget.state.currentPage == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
              boxShadow:
                  widget.state.currentPage == index
                      ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final isLastPage = widget.state.currentPage == widget.pages.length - 1;

    return AnimatedBuilder(
      animation: _contentAnimController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      widget.onAction(
                        const OnboardingAction.completeOnboarding(),
                      );
                    } else {
                      widget.onAction(const OnboardingAction.nextPage());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        widget.pages[widget.state.currentPage].backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isLastPage ? '시작하기' : '다음',
                    style: AppTextStyles.button1Medium.copyWith(
                      fontSize: 18,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color:
                          widget
                              .pages[widget.state.currentPage]
                              .backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 주어진 색상보다 약간 더 어두운 색상 반환
  Color _getDarkerColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }
}
