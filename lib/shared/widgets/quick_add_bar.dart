import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 하단 고정 할일 빠른 추가 바.
///
/// 제목만 입력해서 즉시 추가 + 아이콘 행(기한, 알림, 반복)으로 세부 설정 가능.
class QuickAddBar extends StatefulWidget {
  const QuickAddBar({
    super.key,
    required this.onAdd,
    this.onSetDueDate,
    this.onSetReminder,
    this.onSetRepeat,
    this.hintText = '할 일 추가',
  });

  /// 제목을 받아 태스크를 생성한다. 빈 문자열은 호출하지 않음.
  final void Function(String title) onAdd;

  /// 기한 아이콘 탭
  final VoidCallback? onSetDueDate;

  /// 알림 아이콘 탭
  final VoidCallback? onSetReminder;

  /// 반복 아이콘 탭
  final VoidCallback? onSetRepeat;

  final String hintText;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(title);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 입력 행
              Row(
                children: [
                  // + 아이콘
                  Icon(
                    Icons.add_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  // 텍스트 입력
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AppTextStyles.body(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.body(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  // 완료 버튼 (텍스트 있을 때만 활성)
                  if (_hasText)
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // 아이콘 행 (기한 / 알림 / 반복)
              Row(
                children: [
                  _IconAction(
                    icon: Icons.calendar_today_outlined,
                    label: '기한',
                    onTap: widget.onSetDueDate,
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.notifications_none_rounded,
                    label: '알림',
                    onTap: widget.onSetReminder,
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Icons.repeat_rounded,
                    label: '반복',
                    onTap: widget.onSetRepeat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(label, style: AppTextStyles.label(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
