import 'package:flutter/material.dart';

/// DESIGN.md 기반 색상 토큰
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Light mode
  // ---------------------------------------------------------------------------

  /// 앱 배경 — 따뜻한 오프화이트 (순백 아님)
  static const background = Color(0xFFF8F8F6);

  /// 카드/서피스
  static const surface = Color(0xFFFFFFFF);

  /// 주 텍스트
  static const textPrimary = Color(0xFF1C1C1E);

  /// 보조 텍스트 (서브타이틀, 플레이스홀더)
  static const textMuted = Color(0xFF6E6E73);

  /// 액센트 — MS Todo보다 따뜻하고 개인적인 블루
  static const accent = Color(0xFF4E7EFF);

  /// 구분선
  static const divider = Color(0xFFE5E5EA);

  // ---------------------------------------------------------------------------
  // Dark mode
  // ---------------------------------------------------------------------------

  static const backgroundDark = Color(0xFF1C1C1E);
  static const surfaceDark = Color(0xFF2C2C2E);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textMutedDark = Color(0xFF8E8E93);
  static const accentDark = Color(0xFF4370E8);
  static const dividerDark = Color(0xFF3A3A3C);

  // ---------------------------------------------------------------------------
  // 시맨틱
  // ---------------------------------------------------------------------------

  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const info = Color(0xFF4E7EFF);

  // ---------------------------------------------------------------------------
  // 프로젝트 테마 컬러 (6종 프리셋)
  // ---------------------------------------------------------------------------

  static const projectBlue = Color(0xFF4E7EFF);
  static const projectPurple = Color(0xFF9B6DFF);
  static const projectRed = Color(0xFFFF453A);
  static const projectGreen = Color(0xFF34C759);
  static const projectOrange = Color(0xFFFF9F0A);
  static const projectTeal = Color(0xFF32ADE6);

  static const List<Color> projectPresets = [
    projectBlue,
    projectPurple,
    projectRed,
    projectGreen,
    projectOrange,
    projectTeal,
  ];

  // ---------------------------------------------------------------------------
  // 오늘 화면 시간대별 그라디언트
  // ---------------------------------------------------------------------------

  /// 아침 (06:00–10:00): 살구 → 청록
  static const todayMorning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD89B), Color(0xFF19547B)],
  );

  /// 낮 (10:00–17:00): 밝은 청 → 인디고
  static const todayDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  );

  /// 저녁 (17:00–21:00): 보라 → 핑크
  static const todayEvening = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
  );

  /// 밤 (21:00–06:00): 딥네이비 → 미드나이트
  static const todayNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
  );

  /// 현재 시각 기준으로 오늘 화면 그라디언트를 반환한다.
  static LinearGradient todayGradientForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) return todayMorning;
    if (hour >= 10 && hour < 17) return todayDay;
    if (hour >= 17 && hour < 21) return todayEvening;
    return todayNight;
  }
}
