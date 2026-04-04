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

/// Inbox 뷰 — projectId == null 인 태스크 목록.
class InboxView extends ConsumerWidget {
  const InboxView({super.key, this.onTaskTap});

  final void Function(Task)? onTaskTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_inboxTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tasksAsync.when(
        loading: () => const _LoadingBody(),
        error: (e, st) => _ErrorBody(error: e.toString()),
        data: (tasks) {
          final active = tasks.where((t) => !t.completed).toList();
          final completed = tasks.where((t) => t.completed).toList();

          return ListView(
            children: [
              ...active.map((task) => TaskListItem(
                    key: ValueKey(task.id),
                    task: task,
                    onToggleComplete: () => _toggleComplete(context, ref, task),
                    onTap: () => onTaskTap?.call(task),
                    onToggleFocus: () => ref
                        .read(taskRepositoryProvider)
                        .setFocused(task, isFocused: !task.isFocused),
                  )),
              if (completed.isNotEmpty)
                CompletedSection(
                  tasks: completed,
                  onToggleComplete: (t) => _toggleComplete(context, ref, t),
                  onTaskTap: (t) => onTaskTap?.call(t),
                  onToggleFocus: (t) => ref
                      .read(taskRepositoryProvider)
                      .setFocused(t, isFocused: !t.isFocused),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomSheet: QuickAddBar(
        onAdd: (title) {
          final tasks = ref.read(_inboxTasksProvider).valueOrNull ?? [];
          final maxOrder = tasks.isEmpty
              ? 0.0
              : tasks.map((t) => t.order).reduce(max);
          ref.read(taskRepositoryProvider).createTask(
                title: title,
                order: maxOrder + 1000.0,
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
// Provider (뷰 로컬) — Inbox 태스크 (projectId == null)
// ---------------------------------------------------------------------------

final _inboxTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchActiveTasks().map(
        (tasks) => tasks.where((t) => t.projectId == null).toList(),
      );
});

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
