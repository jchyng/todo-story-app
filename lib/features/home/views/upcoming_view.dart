import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/completed_section.dart';
import '../../../shared/widgets/task_list_item.dart';
import '../../../shared/widgets/undo_snackbar.dart';

/// Upcoming 뷰 — dueDate가 있는 태스크를 날짜별 섹션으로 그룹핑.
class UpcomingView extends ConsumerWidget {
  const UpcomingView({super.key, this.onTaskTap});

  final void Function(Task)? onTaskTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_upcomingTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tasksAsync.when(
        loading: () => const _LoadingBody(),
        error: (e, st) => _ErrorBody(error: e.toString()),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                '기한이 있는 할 일이 없습니다',
                style: AppTextStyles.body(color: AppColors.textMuted),
              ),
            );
          }

          // 날짜별 그룹핑 (날짜 오름차순)
          final grouped = <String, List<Task>>{};
          for (final task in tasks) {
            final key = task.dueDate!;
            grouped.putIfAbsent(key, () => []).add(task);
          }
          final sortedDates = grouped.keys.toList()..sort();

          return ListView(
            children: [
              for (final date in sortedDates) ...[
                _DateSectionHeader(date: date),
                ...grouped[date]!
                    .where((t) => !t.completed)
                    .map((task) => TaskListItem(
                          key: ValueKey(task.id),
                          task: task,
                          onToggleComplete: () =>
                              _toggleComplete(context, ref, task),
                          onTap: () => onTaskTap?.call(task),
                          onToggleFocus: () => ref
                              .read(taskRepositoryProvider)
                              .setFocused(task, isFocused: !task.isFocused),
                          showProjectName: task.projectId != null,
                        )),
                // 완료된 태스크 (날짜별 섹션 내 접기)
                if (grouped[date]!.any((t) => t.completed))
                  CompletedSection(
                    tasks: grouped[date]!.where((t) => t.completed).toList(),
                    onToggleComplete: (t) => _toggleComplete(context, ref, t),
                    onTaskTap: (t) => onTaskTap?.call(t),
                    onToggleFocus: (t) => ref
                        .read(taskRepositoryProvider)
                        .setFocused(t, isFocused: !t.isFocused),
                    showProjectName: true,
                  ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final repo = ref.read(taskRepositoryProvider);
    final wasCompleted = task.completed;
    await repo.toggleComplete(task.id, completed: !wasCompleted);
    if (!wasCompleted && context.mounted) {
      UndoSnackbar.show(
        context,
        message: '할 일을 완료했습니다',
        onUndo: () => repo.toggleComplete(task.id, completed: false),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider (뷰 로컬)
// ---------------------------------------------------------------------------

final _upcomingTasksProvider = Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  return ref.watch(activeTasksStreamProvider).whenData(
        (tasks) => tasks.where((t) => t.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)),
      );
});

// ---------------------------------------------------------------------------
// 날짜 섹션 헤더
// ---------------------------------------------------------------------------

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.date});

  final String date; // "YYYY-MM-DD"

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        _formatDate(date),
        style: AppTextStyles.label(color: AppColors.textMuted),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final diff = d.difference(todayOnly).inDays;

      final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
      final dayName = weekdays[d.weekday % 7];

      if (diff == 0) return '오늘 · ${d.month}월 ${d.day}일 $dayName요일';
      if (diff == 1) return '내일 · ${d.month}월 ${d.day}일 $dayName요일';
      if (diff < 0) return '${d.month}월 ${d.day}일 $dayName요일 (지남)';
      return '${d.month}월 ${d.day}일 $dayName요일';
    } catch (_) {
      return date;
    }
  }
}

// ---------------------------------------------------------------------------
// 공통 상태 위젯
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(error, style: AppTextStyles.body(color: AppColors.textMuted)),
    );
  }
}
