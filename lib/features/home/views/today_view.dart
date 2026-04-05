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

/// Today 뷰 — isFocused == true 또는 dueDate == 오늘인 태스크 + DnD.
///
/// DnD는 focusOrder 필드만 수정한다 (order 필드 불변).
class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key, this.onTaskTap});

  final void Function(Task)? onTaskTap;

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  List<Task>? _optimisticActive;
  bool _isRebalancing = false;

  void _onReorder(List<Task> active, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final snapshot = [...active];
    final items = [...active];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _optimisticActive = items);

    final prevOrder = newIndex > 0
        ? (items[newIndex - 1].focusOrder ?? items[newIndex - 1].order)
        : null;
    final nextOrder = newIndex < items.length - 1
        ? (items[newIndex + 1].focusOrder ?? items[newIndex + 1].order)
        : null;

    final newOrder = _computeOrder(prevOrder, nextOrder);
    final repo = ref.read(taskRepositoryProvider);

    final needsRebalance = prevOrder != null &&
        nextOrder != null &&
        (nextOrder - prevOrder).abs() < 1e-10;

    if (needsRebalance) {
      setState(() => _isRebalancing = true);
      try {
        await repo.rebalanceOrder(items, useFocusOrder: true);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _optimisticActive = snapshot;
          _isRebalancing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('순서 변경에 실패했습니다. 다시 시도해주세요.',
              style: AppTextStyles.body()),
          backgroundColor: AppColors.surface,
        ));
        return;
      }
      if (mounted) setState(() => _isRebalancing = false);
    } else {
      await repo.updateFocusOrder(moved.id, newOrder);
    }

    if (mounted) setState(() => _optimisticActive = null);
  }

  double _computeOrder(double? prev, double? next) {
    if (prev == null && next == null) return 1000.0;
    if (prev == null) return next! / 2;
    if (next == null) return prev + 1000.0;
    return (prev + next) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(_todayTasksProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TodayHeader()),
          tasksAsync.when(
            loading: () => const SliverFillRemaining(child: _LoadingBody()),
            error: (e, st) =>
                SliverFillRemaining(child: _ErrorBody(error: e.toString())),
            data: (tasks) {
              final sorted = tasks.where((t) => !t.completed).toList()
                ..sort((a, b) {
                  final ao = a.focusOrder ?? a.order;
                  final bo = b.focusOrder ?? b.order;
                  return ao.compareTo(bo);
                });
              final active = _optimisticActive ?? sorted;
              final completed = tasks.where((t) => t.completed).toList();

              return SliverFillRemaining(
                hasScrollBody: true,
                child: ReorderableListView(
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
                          showProjectName: true,
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
                            showProjectName: task.projectId != null,
                          ))
                      .toList(),
                ),
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
        ),
        if (_isRebalancing)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ),
      ],
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

  Widget _proxyDecorator(Widget child, int index, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Material(
        elevation: 4 * anim.value,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final today = _todayString();
  return repo.watchActiveTasks().map(
        (tasks) =>
            tasks.where((t) => t.isFocused || t.dueDate == today).toList(),
      );
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
            style:
                AppTextStyles.title(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 2),
          Text('오늘', style: AppTextStyles.display(color: Colors.white)),
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
