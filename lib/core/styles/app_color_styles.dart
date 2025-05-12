import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 시스템 정의
/// 브랜드 색상, 상태 색상, 텍스트 색상, 배경 색상, 회색 계열 등 포함
class AppColorStyles {
  AppColorStyles._(); // 인스턴스화 방지를 위한 private 생성자

  // ====== 브랜드 색상 ======

  /// 메인 브랜드 색상 - Primary
  static const Color primary100 = Color(0xFF5D5FEF);
  static const Color primary80 = Color(0xFF7879F1);
  static const Color primary60 = Color(0xFFA5A6F6);

  /// 보조 브랜드 색상 - Secondary
  static const Color secondary01 = Color(0xFFEF5DA8);
  static const Color secondary02 = Color(0xFFF178B6);
  static const Color secondary03 = Color(0xFFFCDDEC);

  // ====== 상태 색상 ======

  /// 성공 상태 표시 색상
  static const Color success = Color(0xFF33B469);

  /// 경고 상태 표시 색상
  static const Color warning = Color(0xFFEBBC2E);

  /// 정보 상태 표시 색상
  static const Color info = Color(0xFF2F80ED);

  /// 오류 상태 표시 색상
  static const Color error = Color(0xFFED3A3A);

  // ====== 텍스트 색상 ======

  /// 기본 텍스트 색상 (거의 검정)
  static const Color textPrimary = Color(0xFF262424);

  // ====== 배경 색상 ======

  /// 기본 배경 색상
  static const Color background = Color(0xFFF6F6F6);

  // ====== 회색 계열 ======

  /// 가장 진한 회색 (100%)
  static const Color gray100 = Color(0xFFA7A7A7);

  /// 진한 회색 (80%)
  static const Color gray80 = Color(0xFFBEBEBE);

  /// 중간 회색 (60%)
  static const Color gray60 = Color(0xFFCFCFCF);

  /// 밝은 회색 (40%)
  static const Color gray40 = Color(0xFFE3E3E3);

  // ====== 추가 유틸리티 색상 ======

  /// 순수한 흰색
  static const Color white = Colors.white;

  /// 순수한 검정
  static const Color black = Colors.black;

  /// 반투명 검정 (오버레이에 사용)
  static Color blackOverlay(double opacity) => black.withValues(alpha: opacity);

  /// 반투명 흰색 (오버레이에 사용)
  static Color whiteOverlay(double opacity) => white.withValues(alpha: opacity);

  // ====== 색상 효과 ======

  /// 버튼이나 카드에 사용할 수 있는 그라데이션
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary100, primary80],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => const LinearGradient(
    colors: [secondary01, secondary02],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}