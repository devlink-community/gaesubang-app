import 'package:flutter/material.dart';
import 'app_color_styles.dart';

/// 앱 전체에서 사용하는 텍스트 스타일 정의
/// 모든 텍스트는 Roboto 폰트를 기본으로 사용합니다.
/// ****** copyWith() 메서드를 사용하여 스타일을 변경할 수 있습니다. ******
/// 예시:
/// ```dart
/// Text(
///   'Hello, World!',
///   style: AppTextStyles.displayBold.copyWith(color: Colors.red),
/// )
/// ```
/// 위와 같이 사용하면 displayBold 스타일을 기반으로 색상만 빨간색으로 변경됩니다.
class AppTextStyles {
  AppTextStyles._(); // 인스턴스화 방지를 위한 private 생성자

  // 기본 폰트 패밀리
  static const String _fontFamily = 'Roboto';

  // 폰트 가중치
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ====== Display 스타일 ======

  /// DisplayBold - 75dp / 75sp / 3.5rem / 56px
  /// 특대형 제목, 배너, 랜딩 페이지 등 매우 큰 텍스트에 사용
  static const TextStyle displayBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 56,
    fontWeight: extraBold,
    height: 1.2, // line-height: 67.2px
    color: AppColorStyles.textPrimary,
  );

  /// DisplayRegular - 75dp / 75sp / 3.5rem / 56px
  /// 특대형 제목의 일반 가중치 버전
  static const TextStyle displayRegular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 56,
    fontWeight: regular,
    height: 1.2, // line-height: 67.2px
    color: AppColorStyles.textPrimary,
  );

  // ====== Heading 스타일 ======

  /// Heading1Bold - 53dp / 53sp / 2.5rem / 40px
  /// 메인 제목, 섹션 구분 등 큰 텍스트에 사용
  static const TextStyle heading1Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: bold,
    height: 1.2, // line-height: 48px
    color: AppColorStyles.textPrimary,
  );

  /// Heading1Regular - 53dp / 53sp / 2.5rem / 40px
  /// 메인 제목의 일반 가중치 버전
  static const TextStyle heading1Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: regular,
    height: 1.2, // line-height: 48px
    color: AppColorStyles.textPrimary,
  );

  /// Heading2Bold - 43dp / 43sp / 2rem / 32px
  /// 서브 제목, 주요 섹션 내 제목 등에 사용
  static const TextStyle heading2Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: bold,
    height: 1.2, // line-height: 38.4px
    color: AppColorStyles.textPrimary,
  );

  /// Heading2Regular - 43dp / 43sp / 2rem / 32px
  /// 서브 제목의 일반 가중치 버전
  static const TextStyle heading2Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: regular,
    height: 1.2, // line-height: 38.4px
    color: AppColorStyles.textPrimary,
  );

  /// Heading3Bold - 32dp / 32sp / 1.5rem / 24px
  /// 소제목, 카드 제목 등에 사용
  static const TextStyle heading3Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: bold,
    height: 1.2, // line-height: 28.8px
    color: AppColorStyles.textPrimary,
  );

  /// Heading3Regular - 32dp / 32sp / 1.5rem / 24px
  /// 소제목의 일반 가중치 버전
  static const TextStyle heading3Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: regular,
    height: 1.2, // line-height: 28.8px
    color: AppColorStyles.textPrimary,
  );

  /// Heading6Bold - 27dp / 27sp / 1.25rem / 20px
  /// 작은 제목, 리스트 아이템 제목 등에 사용
  static const TextStyle heading6Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: bold,
    height: 1.2, // line-height: 24px
    color: AppColorStyles.textPrimary,
  );

  /// Heading6Regular - 27dp / 27sp / 1.25rem / 20px
  /// 작은 제목의 일반 가중치 버전
  static const TextStyle heading6Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: regular,
    height: 1.2, // line-height: 24px
    color: AppColorStyles.textPrimary,
  );

  // ====== Subtitle 스타일 ======

  /// Subtitle1Bold - 24dp / 24sp / 1.125rem / 18px
  /// 부제목, 강조 텍스트에 사용
  static const TextStyle subtitle1Bold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: bold,
    height: 1.2, // line-height: 21.6px
    color: AppColorStyles.textPrimary,
  );

  /// Subtitle1Medium - 24dp / 24sp / 1.125rem / 18px
  /// 부제목의 중간 가중치 버전
  static const TextStyle subtitle1Medium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: medium,
    height: 1.2, // line-height: 21.6px
    color: AppColorStyles.textPrimary,
  );

  /// Subtitle2Regular - 21dp / 21sp / 1rem / 16px
  /// 일반 부제목, 메뉴 항목 등에 사용
  static const TextStyle subtitle2Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: regular,
    height: 1.2, // line-height: 19.2px
    color: AppColorStyles.textPrimary,
  );

  // ====== Body 스타일 ======

  /// Body1Regular - 19dp / 19sp / 0.875rem / 14px
  /// 본문 텍스트, 설명 등에 사용
  static const TextStyle body1Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: regular,
    height: 1.4, // line-height: 19.6px
    color: AppColorStyles.textPrimary,
  );

  /// Body2Regular - 19dp / 19sp / 0.875rem / 14px
  /// 보조 본문 텍스트에 사용
  static const TextStyle body2Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: regular,
    height: 1.4, // line-height: 19.6px
    color: AppColorStyles.textPrimary,
  );

  // ====== Button 스타일 ======

  /// Button1Medium - 21dp / 21sp / 1rem / 16px
  /// 주요 버튼 텍스트에 사용
  static const TextStyle button1Medium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: medium,
    height: 1.2, // line-height: 19.2px
    color: AppColorStyles.textPrimary,
  );

  /// Button2Regular - 19dp / 19sp / 0.875rem / 14px
  /// 보조 버튼 텍스트에 사용
  static const TextStyle button2Regular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: regular,
    height: 1.2, // line-height: 16.8px
    color: AppColorStyles.textPrimary,
  );

  // ====== Caption 스타일 ======

  /// CaptionRegular - 16dp / 16sp / 0.75rem / 12px
  /// 캡션, 주석, 작은 설명 등에 사용
  static const TextStyle captionRegular = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: regular,
    height: 1.2, // line-height: 14.4px
    color: AppColorStyles.textPrimary,
  );

  // ====== 유틸리티 함수 ======

  /// 텍스트 스타일에 색상 변경하기
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 텍스트 스타일에 줄 간격 변경하기
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  /// 텍스트 스타일에 밑줄 추가하기
  static TextStyle withUnderline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// 텍스트 스타일에 취소선 추가하기
  static TextStyle withStrikethrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }
}
