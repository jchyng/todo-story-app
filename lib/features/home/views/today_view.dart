import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/completed_section.dart';
import '../../../shared/widgets/quick_add_bar.dart';
import '../../../shared/widgets/task_list_item.dart';
import '../../../shared/widgets/undo_snackbar.dart';

/// Today 뷰 — isFocused == true 또는 dueDate == 오늘인 태스크.
///
/// 헤더: 시간대별 그라디언트 + 오늘 날짜 대형 표시
class TodayView extends ConsumerWidget {
  const TodayView({super.key, this.onTaskTap});

  final void Function(Task)? onTaskTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_todayTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TodayHeader()),
          tasksAsync.when(
            loading: () => const SliverFillRemaining(child: _LoadingBody()),
            error: (e, st) =>
                SliverFillRemaining(child: _ErrorBody(error: e.toString())),
            data: (tasks) {
              final active = tasks.where((t) => !t.completed).toList()
                ..sort((a, b) {
                  final aOrder = a.focusOrder ?? a.order;
                  final bOrder = b.focusOrder ?? b.order;
                  return aOrder.compareTo(bOrder);
                });
              final completed = tasks.where((t) => t.completed).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  ...active.map((task) => TaskListItem(
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
                  if (completed.isNotEmpty)
                    CompletedSection(
                      tasks: completed,
                      onToggleComplete: (t) =>
                          _toggleComplete(context, ref, t),
                      onTaskTap: (t) => onTaskTap?.call(t),
                      onToggleFocus: (t) => ref
                          .read(taskRepositoryProvider)
                          .setFocused(t, isFocused: !t.isFocused),
                      showProjectName: true,
                    ),
                  const SizedBox(height: 80),
                ]),
              );
            },
          ),
        ],
      ),
      bottomSheet: QuickAddBar(
        hintText: '오늘 할 일 추가',
        onAdd: (title) {
          final tasks = ref.read(_todayTasksProvider).valueOrNull ?? [];
          final maxOrder = tasks.isEmpty
              ? 0.0
              : tasks.map((t) => t.focusOrder ?? t.order).reduce(max);
          ref.read(taskRepositoryProvider).createTask(
                title: title,
                order: maxOrder + 1000.0,
                isFocused: true,
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

final _todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final today = _todayString();
  return repo
      .watchActiveTasks()
      .map((tasks) => tasks.where((t) => t.isFocused || t.dueDate == today).toList());
});

String _todayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// 헤더
// ---------------------------------------------------------------------------

class _TodayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.todayGradientForNow();
    final now = DateTime.now();
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      height: 140,
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${now.month}월 ${now.day}일 ${weekdays[now.weekday % 7]}요일',
            style: AppTextStyles.title(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 2),
          Text(
            '오늘',
            style: AppTextStyles.display(color: Colors.white),
          ),
        ],
      ),
    );
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
