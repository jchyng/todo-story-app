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

/// Inbox 뷰 — projectId == null 인 태스크 목록 + DnD 정렬.
class InboxView extends ConsumerStatefulWidget {
  const InboxView({super.key, this.onTaskTap});

  final void Function(Task)? onTaskTap;

  @override
  ConsumerState<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends ConsumerState<InboxView> {
  /// DnD 진행 중 Firestore 스트림이 덮어쓰지 않도록 낙관적 로컬 순서를 잠깐 유지.
  List<Task>? _optimisticActive;

  void _onReorder(List<Task> active, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    // 낙관적 UI 업데이트
    final items = [...active];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _optimisticActive = items);

    final prevOrder = newIndex > 0 ? items[newIndex - 1].order : null;
    final nextOrder =
        newIndex < items.length - 1 ? items[newIndex + 1].order : null;

    final newOrder = _computeOrder(prevOrder, nextOrder);
    final repo = ref.read(taskRepositoryProvider);

    // gap이 너무 좁으면 전체 리밸런싱
    final needsRebalance = prevOrder != null &&
        nextOrder != null &&
        (nextOrder - prevOrder).abs() < 1e-10;

    if (needsRebalance) {
      await repo.rebalanceOrder(items);
    } else {
      await repo.updateOrder(moved.id, newOrder);
    }

    // Firestore 스트림이 업데이트되면 낙관적 상태 해제
    setState(() => _optimisticActive = null);
  }

  double _computeOrder(double? prev, double? next) {
    if (prev == null && next == null) return 1000.0;
    if (prev == null) return next! / 2;
    if (next == null) return prev + 1000.0;
    return (prev + next) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(_inboxTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tasksAsync.when(
        loading: () => const _LoadingBody(),
        error: (e, st) => _ErrorBody(error: e.toString()),
        data: (tasks) {
          final active = _optimisticActive ??
              tasks.where((t) => !t.completed).toList();
          final completed = tasks.where((t) => t.completed).toList();

          return ReorderableListView(
            onReorder: (o, n) => _onReorder(active, o, n),
            proxyDecorator: _proxyDecorator,
            footer: Column(
              children: [
                if (completed.isNotEmpty)
                  CompletedSection(
                    tasks: completed,
                    onToggleComplete: (t) => _toggleComplete(t),
                    onTaskTap: (t) => widget.onTaskTap?.call(t),
                    onToggleFocus: (t) => ref
                        .read(taskRepositoryProvider)
                        .setFocused(t, isFocused: !t.isFocused),
                  ),
                const SizedBox(height: 80),
              ],
            ),
            children: active
                .map((task) => TaskListItem(
                      key: ValueKey(task.id),
                      task: task,
                      onToggleComplete: () => _toggleComplete(task),
                      onTap: () => widget.onTaskTap?.call(task),
                      onToggleFocus: () => ref
                          .read(taskRepositoryProvider)
                          .setFocused(task, isFocused: !task.isFocused),
                    ))
                .toList(),
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

  Future<void> _toggleComplete(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final wasCompleted = task.completed;
    await repo.toggleComplete(task.id, completed: !wasCompleted);
    if (!wasCompleted && mounted) {
      UndoSnackbar.show(
        context,
        message: '할 일을 완료했습니다',
        onUndo: () => repo.toggleComplete(task.id, completed: false),
      );
    }
  }

  /// DnD 드래그 중 반투명 떠있는 아이템 스타일
  Widget _proxyDecorator(Widget child, int index, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Material(
          elevation: 4 * anim.value,
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          child: child,
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
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
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.accent));
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Center(
        child: Text(error, style: AppTextStyles.body(color: AppColors.textMuted)),
      );
}
