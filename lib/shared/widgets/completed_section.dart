import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task_model.dart';
import 'task_list_item.dart';

/// "완료 N개" 접기/펼치기 섹션.
///
/// 기본값: 접힌 상태 (isExpanded: false)
class CompletedSection extends StatefulWidget {
  const CompletedSection({
    super.key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onTaskTap,
    this.onToggleFocus,
    this.projectColor,
    this.showProjectName = false,
    this.projectNameOf,
  });

  final List<Task> tasks;
  final Future<void> Function(Task) onToggleComplete;
  final void Function(Task) onTaskTap;
  final void Function(Task)? onToggleFocus;
  final Color? projectColor;
  final bool showProjectName;
  final String? Function(String projectId)? projectNameOf;

  @override
  State<CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<CompletedSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _rotateCtrl.forward();
    } else {
      _rotateCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // 헤더 행
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.25).animate(
                    CurvedAnimation(
                      parent: _rotateCtrl,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '완료 ${widget.tasks.length}개',
                  style: AppTextStyles.body(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        // 완료된 태스크 목록 (펼쳤을 때만)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.tasks.map((task) {
              return TaskListItem(
                key: ValueKey(task.id),
                task: task,
                onToggleComplete: () => widget.onToggleComplete(task),  // async propagated via Future
                onTap: () => widget.onTaskTap(task),
                onToggleFocus: widget.onToggleFocus != null
                    ? () => widget.onToggleFocus!(task)
                    : null,
                projectColor: widget.projectColor,
                showProjectName: widget.showProjectName,
                projectName: task.projectId != null
                    ? widget.projectNameOf?.call(task.projectId!)
                    : null,
              );
            }).toList(),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
