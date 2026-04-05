import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DESIGN.md 기반 텍스트 스타일
///
/// UI 전반: Plus Jakarta Sans
/// Timeline 월/연도 헤더: Fraunces (세리프) — 해당 위젯에서 직접 사용
/// 숫자/통계: Geist Mono (tabular-nums)
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Plus Jakarta Sans — UI 전반
  // ---------------------------------------------------------------------------

  /// Display — 프로젝트 헤더 타이틀 (28sp, Bold)
  static TextStyle display({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  /// Title — 화면 타이틀, Today 날짜 (20sp, SemiBold)
  static TextStyle title({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  /// Headline — 할일 제목 (17sp, Medium)
  static TextStyle headline({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  /// Body — 서브텍스트, 메모, 날짜 (14sp, Regular)
  static TextStyle body({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  /// Label — 배지, 보조 레이블 (12sp, Regular)
  static TextStyle label({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Fraunces — Timeline 뷰 월/연도 헤더 전용 (세리프)
  // ---------------------------------------------------------------------------

  /// Timeline 월 헤더 (24sp, SemiBold, 세리프)
  static TextStyle timelineMonth({Color? color}) => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
        fontStyle: FontStyle.normal,
      );

  /// Timeline 연도 레이블 (13sp, Regular, 세리프)
  static TextStyle timelineYear({Color? color}) => GoogleFonts.fraunces(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Geist Mono — 숫자/통계 (tabular-nums)
  // ---------------------------------------------------------------------------

  /// 통계 수치 (13sp, Regular, 고정폭)
  static TextStyle mono({Color? color}) => GoogleFonts.getFont(
        'Geist Mono',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
