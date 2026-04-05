import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/settings_provider.dart';

/// 설정 화면.
///
/// AppDrawer에서 push navigation으로 진입한다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('설정', style: AppTextStyles.title()),
      ),
      body: ListView(
        children: [
          // ── 외관 ──────────────────────────────────────────────
          _SectionHeader('외관'),
          _SegmentTile<String>(
            label: '다크 모드',
            icon: Icons.dark_mode_outlined,
            options: const [
              _SegmentOption('system', '시스템'),
              _SegmentOption('light', '라이트'),
              _SegmentOption('dark', '다크'),
            ],
            selected: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v),
          ),

          // ── 일반 ──────────────────────────────────────────────
          _SectionHeader('일반'),
          _SegmentTile<String>(
            label: '주 시작일',
            icon: Icons.calendar_today_outlined,
            options: const [
              _SegmentOption('mon', '월요일'),
              _SegmentOption('sun', '일요일'),
            ],
            selected: settings.startOfWeek,
            onChanged: (v) => notifier.setStartOfWeek(v),
          ),
          _SegmentTile<String>(
            label: '시간 형식',
            icon: Icons.schedule_outlined,
            options: const [
              _SegmentOption('24h', '24시간'),
              _SegmentOption('12h', '12시간'),
            ],
            selected: settings.timeFormat,
            onChanged: (v) => notifier.setTimeFormat(v),
          ),

          // ── 알림 ──────────────────────────────────────────────
          _SectionHeader('알림'),
          _SwitchTile(
            label: '푸시 알림',
            icon: Icons.notifications_outlined,
            value: settings.pushEnabled,
            onChanged: (v) => notifier.setPushEnabled(v),
          ),
          _SwitchTile(
            label: '일일 요약',
            icon: Icons.summarize_outlined,
            value: settings.dailySummaryEnabled,
            onChanged: (v) => notifier.setDailySummaryEnabled(v),
          ),
          if (settings.dailySummaryEnabled)
            _TimePickerTile(
              label: '알림 시간',
              icon: Icons.alarm_outlined,
              time: settings.dailySummaryTime,
              onChanged: (t) => notifier.setDailySummaryTime(t),
            ),

          // ── 캘린더 동기화 ──────────────────────────────────────
          _SectionHeader('캘린더 동기화'),
          _InfoTile(
            label: 'Google Calendar',
            icon: Icons.event_outlined,
            trailingLabel: '연결되지 않음',
            onTap: null, // Phase 4에서 구현
          ),
          _SwitchTile(
            label: 'Galaxy 캘린더',
            icon: Icons.phone_android_outlined,
            value: false,
            onChanged: null, // Phase 4에서 구현
          ),

          // ── 계정 ──────────────────────────────────────────────
          _SectionHeader('계정'),
          _ActionTile(
            label: '로그아웃',
            icon: Icons.logout_rounded,
            onTap: () => _logout(context),
          ),
          _ActionTile(
            label: '계정 삭제',
            icon: Icons.delete_forever_outlined,
            color: AppColors.error,
            onTap: () => _deleteAccount(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('로그아웃', style: AppTextStyles.headline()),
        content: Text('로그아웃하시겠어요?',
            style: AppTextStyles.body(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child:
                Text('로그아웃', style: AppTextStyles.body(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('계정 삭제', style: AppTextStyles.headline()),
        content: Text(
          '계정을 삭제하면 모든 할 일과 프로젝트 데이터가 영구적으로 삭제됩니다.\n계속하시겠어요?',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('다음',
                style: AppTextStyles.body(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('정말로 삭제할까요?', style: AppTextStyles.headline()),
        content: Text(
          '이 작업은 되돌릴 수 없습니다.',
          style: AppTextStyles.body(color: AppColors.error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('계정 삭제',
                style: AppTextStyles.body(color: Colors.white)),
          ),
        ],
      ),
    );
    if (step2 != true) return;

    await FirebaseAuth.instance.currentUser?.delete();
    await GoogleSignIn().signOut();
  }
}

// ---------------------------------------------------------------------------
// 섹션 헤더
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(title, style: AppTextStyles.label(color: AppColors.textMuted)),
    );
  }
}

// ---------------------------------------------------------------------------
// 세그먼트 타일 (2~3 선택지)
// ---------------------------------------------------------------------------

class _SegmentOption<T> {
  const _SegmentOption(this.value, this.label);
  final T value;
  final String label;
}

class _SegmentTile<T> extends StatelessWidget {
  const _SegmentTile({
    required this.label,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<_SegmentOption<T>> options;
  final T selected;
  final void Function(T)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)),
          const Spacer(),
          SegmentedButton<T>(
            segments: options
                .map((o) => ButtonSegment<T>(
                      value: o.value,
                      label: Text(o.label,
                          style: AppTextStyles.label(
                              color: AppColors.textPrimary)),
                    ))
                .toList(),
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: onChanged != null
                ? (vals) => onChanged!(vals.first)
                : null,
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.background,
              selectedBackgroundColor: AppColors.accent,
              selectedForegroundColor: Colors.white,
              side: const BorderSide(color: AppColors.divider),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 스위치 타일
// ---------------------------------------------------------------------------

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(icon, size: 20, color: AppColors.textMuted),
      title: Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.accent,
      activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
    );
  }
}

// ---------------------------------------------------------------------------
// 시간 선택 타일
// ---------------------------------------------------------------------------

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.icon,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String time;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: AppColors.textMuted),
      title: Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)),
      trailing: TextButton(
        onPressed: () => _pick(context),
        child: Text(time, style: AppTextStyles.mono(color: AppColors.accent)),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final parts = time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(formatted);
    }
  }
}

// ---------------------------------------------------------------------------
// 정보 타일 (연결 상태 표시)
// ---------------------------------------------------------------------------

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.icon,
    required this.trailingLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: AppColors.textMuted),
      title: Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)),
      trailing: Text(trailingLabel,
          style: AppTextStyles.label(color: AppColors.textMuted)),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// 액션 타일 (로그아웃, 계정 삭제)
// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: c),
      title: Text(label, style: AppTextStyles.body(color: c)),
      onTap: onTap,
    );
  }
}
