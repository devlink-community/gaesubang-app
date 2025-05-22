import 'package:flutter/material.dart';

import 'app_color_styles.dart';
import 'app_text_styles.dart';

/// 앱 전체 테마를 정의하는 클래스
/// 라이트 모드와 다크 모드 테마를 모두 포함합니다.
class AppTheme {
  AppTheme._(); // 인스턴스화 방지를 위한 private 생성자

  /// 라이트 모드 테마
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.light,

      // 기본 색상 설정
      primaryColor: AppColorStyles.primary100,
      scaffoldBackgroundColor: AppColorStyles.white,

      // ColorScheme 설정
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColorStyles.primary100,
        onPrimary: AppColorStyles.white,
        secondary: AppColorStyles.secondary01,
        onSecondary: AppColorStyles.white,
        error: AppColorStyles.error,
        onError: AppColorStyles.white,
        // Material 3의 확장된 surface 시스템 (라이트 모드)
        surface: Colors.white,
        // 기본 surface 색상
        onSurface: AppColorStyles.textPrimary,
        // surface 위 텍스트 색상

        // surface container 계층 (라이트 모드)
        surfaceContainerLowest: const Color(0xFFFAF9FD),
        // 가장 낮은 계층
        surfaceContainerLow: const Color(0xFFF5F3F7),
        surfaceContainer: const Color(0xFFEFEDF1),
        surfaceContainerHigh: const Color(0xFFE9E7EC),
        surfaceContainerHighest: const Color(
          0xFFE3E1E6,
        ), // 가장 높은 계층 (이전 background 역할)
      ),

      // 텍스트 테마 설정
      textTheme: TextTheme(
        // Display styles
        displayLarge: AppTextStyles.displayBold,
        displayMedium: AppTextStyles.displayRegular,

        // Headline styles
        headlineLarge: AppTextStyles.heading1Bold,
        headlineMedium: AppTextStyles.heading2Bold,
        headlineSmall: AppTextStyles.heading3Bold,

        // Title styles
        titleLarge: AppTextStyles.heading6Bold,
        titleMedium: AppTextStyles.subtitle1Bold,
        titleSmall: AppTextStyles.subtitle1Medium,

        // Body styles
        bodyLarge: AppTextStyles.subtitle2Regular,
        bodyMedium: AppTextStyles.body1Regular,
        bodySmall: AppTextStyles.body2Regular,

        // Label styles
        labelLarge: AppTextStyles.button1Medium,
        labelMedium: AppTextStyles.button2Regular,
        labelSmall: AppTextStyles.captionRegular,
      ),

      // AppBar 테마
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorStyles.white,
        foregroundColor: AppColorStyles.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.heading6Bold.copyWith(
          color: AppColorStyles.black,
        ),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorStyles.primary100,
          foregroundColor: AppColorStyles.white,
          textStyle: AppTextStyles.button1Medium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

          elevation: 2,
        ),
      ),

      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorStyles.primary100,
          textStyle: AppTextStyles.button2Regular,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // // 아웃라인 버튼 테마
      // outlinedButtonTheme: OutlinedButtonThemeData(
      //   style: OutlinedButton.styleFrom(
      //     foregroundColor: AppColorStyles.primary100,
      //     side: BorderSide(color: AppColorStyles.primary100),
      //     textStyle: AppTextStyles.button1Medium,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      //   ),
      // ),

      

      // 리스트 타일 테마
      listTileTheme: ListTileThemeData(
        tileColor: AppColorStyles.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      
      // 하단 탐색바 테마
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorStyles.white,
        selectedItemColor: AppColorStyles.primary100,
        unselectedItemColor: AppColorStyles.gray80,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.captionRegular.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTextStyles.captionRegular,
        elevation: 8,
      ),

      // 아이콘 테마
      iconTheme: IconThemeData(color: AppColorStyles.textPrimary, size: 24),

      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorStyles.textPrimary,
        contentTextStyle: AppTextStyles.body1Regular.copyWith(
          color: AppColorStyles.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // 자잘한 설정
      dividerTheme: DividerThemeData(
        color: AppColorStyles.gray40,
        thickness: 1,
        space: 1,
      ),

      // 시각적 밀도
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// 다크 모드 테마
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.dark,

      // 기본 색상 설정
      primaryColor: AppColorStyles.primary80,
      // 라이트 모드보다 밝은 색상 사용
      scaffoldBackgroundColor: const Color(0xFF121212),
      // 어두운 배경색

      // ColorScheme 설정
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColorStyles.primary80,
        onPrimary: AppColorStyles.white,
        secondary: AppColorStyles.secondary02,
        // 밝은 보조색
        onSecondary: AppColorStyles.white,
        error: AppColorStyles.error,
        onError: AppColorStyles.white,
        // Material 3의 확장된 surface 시스템 (다크 모드)
        surface: const Color(0xFF1C1B1F),
        // 기본 surface 색상
        onSurface: Colors.white,
        // surface 위 텍스트 색상

        // surface container 계층 (다크 모드)
        surfaceContainerLowest: const Color(0xFF0F0E13),
        // 가장 낮은 계층
        surfaceContainerLow: const Color(0xFF1D1B20),
        surfaceContainer: const Color(0xFF211F26),
        surfaceContainerHigh: const Color(0xFF2B2930),
        surfaceContainerHighest: const Color(
          0xFF36343B,
        ), // 가장 높은 계층 (이전 background 역할)
      ),

      // 텍스트 테마 설정 - 라이트 모드와 동일한 구조이지만 색상 조정
      textTheme: TextTheme(
        // Display styles - 색상을 흰색으로 변경
        displayLarge: AppTextStyles.displayBold.copyWith(
          color: AppColorStyles.white,
        ),
        displayMedium: AppTextStyles.displayRegular.copyWith(
          color: AppColorStyles.white,
        ),

        // Headline styles
        headlineLarge: AppTextStyles.heading1Bold.copyWith(
          color: AppColorStyles.white,
        ),
        headlineMedium: AppTextStyles.heading2Bold.copyWith(
          color: AppColorStyles.white,
        ),
        headlineSmall: AppTextStyles.heading3Bold.copyWith(
          color: AppColorStyles.white,
        ),

        // Title styles
        titleLarge: AppTextStyles.heading6Bold.copyWith(
          color: AppColorStyles.white,
        ),
        titleMedium: AppTextStyles.subtitle1Bold.copyWith(
          color: AppColorStyles.white,
        ),
        titleSmall: AppTextStyles.subtitle1Medium.copyWith(
          color: AppColorStyles.white,
        ),

        // Body styles - 약간 회색빛이 도는 흰색 사용
        bodyLarge: AppTextStyles.subtitle2Regular.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        bodyMedium: AppTextStyles.body1Regular.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        bodySmall: AppTextStyles.body2Regular.copyWith(
          color: const Color(0xFFE0E0E0),
        ),

        // Label styles
        labelLarge: AppTextStyles.button1Medium.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        labelMedium: AppTextStyles.button2Regular.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        labelSmall: AppTextStyles.captionRegular.copyWith(
          color: const Color(0xFFCCCCCC),
        ),
      ),

      // AppBar 테마
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColorStyles.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading6Bold.copyWith(
          color: AppColorStyles.white,
        ),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorStyles.primary80,
          // 더 밝은 프라이머리 색상
          foregroundColor: AppColorStyles.white,
          textStyle: AppTextStyles.button1Medium,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 4, // 더 강한 그림자
        ),
      ),

      // 텍스트 버튼 테마
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorStyles.primary60, // 더 밝은 프라이머리
          textStyle: AppTextStyles.button2Regular,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

    

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242424),
        // 어두운 필드 배경
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorStyles.gray100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorStyles.gray100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorStyles.primary60, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorStyles.error, width: 2),
        ),
        hintStyle: AppTextStyles.body1Regular.copyWith(
          color: AppColorStyles.gray60,
        ),
        labelStyle: AppTextStyles.body1Regular.copyWith(
          color: AppColorStyles.gray60,
        ),
        errorStyle: AppTextStyles.captionRegular.copyWith(
          color: AppColorStyles.error,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // 아이콘 테마
      iconTheme: IconThemeData(color: AppColorStyles.white, size: 24),

      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: AppTextStyles.body1Regular.copyWith(
          color: AppColorStyles.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // 시각적 밀도
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
