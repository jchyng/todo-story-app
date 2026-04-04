import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task_model.dart';

/// 할일 목록 한 행.
///
/// 우측 메타 우선순위: startTime > 서브태스크 진행도 > dueDate
/// 완료 시 취소선 + 체크박스 채우기 애니메이션 (200ms)
/// 마감 지난 태스크: dueDate 텍스트 Error 색상
class TaskListItem extends StatefulWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    this.onToggleFocus,
    this.projectColor,
    this.showProjectName = false,
    this.projectName,
  });

  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;

  /// Today 뷰에서 별 아이콘 표시 시 사용. null이면 별 아이콘 없음.
  final VoidCallback? onToggleFocus;

  /// 프로젝트 뷰 컬러 (체크박스 액센트에 반영)
  final Color? projectColor;

  /// Today/Upcoming 뷰에서 프로젝트명 서브텍스트 표시 여부
  final bool showProjectName;
  final String? projectName;

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkAnim;
  late final Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.task.completed ? 1.0 : 0.0,
    );
    _fillAnim = CurvedAnimation(parent: _checkAnim, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(TaskListItem old) {
    super.didUpdateWidget(old);
    if (widget.task.completed != old.task.completed) {
      if (widget.task.completed) {
        _checkAnim.forward();
      } else {
        _checkAnim.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final accentColor = widget.projectColor ?? AppColors.accent;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 체크박스
            GestureDetector(
              onTap: widget.onToggleComplete,
              child: _AnimatedCheckbox(
                animation: _fillAnim,
                accentColor: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // 제목 + 서브텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _fillAnim,
                    builder: (context, child) {
                      return Text(
                        task.title,
                        style: AppTextStyles.headline(
                          color: task.completed
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ).copyWith(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  if (widget.showProjectName && widget.projectName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.projectName!,
                      style: AppTextStyles.label(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 우측 메타 (startTime > 서브태스크 진행도 > dueDate)
            _buildMeta(task),
            // 별 아이콘 (Today 뷰 / isFocused 토글용)
            if (widget.onToggleFocus != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onToggleFocus,
                child: Icon(
                  task.isFocused ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: task.isFocused ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(Task task) {
    // 우선순위: startTime > 서브태스크 진행도 > dueDate
    if (task.startTime != null) {
      return Text(
        task.startTime!,
        style: AppTextStyles.mono(color: AppColors.textMuted),
      );
    }

    if (task.subtasks.isNotEmpty) {
      final done = task.subtasks.where((s) => s.completed).length;
      return Text(
        '$done/${task.subtasks.length}',
        style: AppTextStyles.mono(color: AppColors.textMuted),
      );
    }

    if (task.dueDate != null) {
      final isOverdue = _isOverdue(task.dueDate!);
      return Text(
        _formatDueDate(task.dueDate!),
        style: AppTextStyles.label(
          color: isOverdue && !task.completed
              ? AppColors.error
              : AppColors.textMuted,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isOverdue(String dueDate) {
    try {
      final parts = dueDate.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      return date.isBefore(todayOnly);
    } catch (_) {
      return false;
    }
  }

  String _formatDueDate(String dueDate) {
    try {
      final parts = dueDate.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final diff = date.difference(todayOnly).inDays;

      if (diff == 0) return '오늘';
      if (diff == 1) return '내일';
      if (diff == -1) return '어제';
      if (diff > 0 && diff < 7) return '${date.month}/${date.day}';
      return '${date.month}/${date.day}';
    } catch (_) {
      return dueDate;
    }
  }
}

/// 애니메이션 체크박스 (원 채우기 효과)
class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.animation,
    required this.accentColor,
  });

  final Animation<double> animation;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(Colors.transparent, accentColor, animation.value),
            border: Border.all(
              color: Color.lerp(AppColors.divider, accentColor, animation.value)!,
              width: 1.5,
            ),
          ),
          child: animation.value > 0.5
              ? Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white.withValues(
                    alpha: ((animation.value - 0.5) * 2).clamp(0.0, 1.0),
                  ),
                )
              : null,
        );
      },
    );
  }
}
