import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../features/task_detail/task_detail_sheet.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/completed_section.dart';
import '../../../shared/widgets/quick_add_bar.dart';
import '../../../shared/widgets/task_list_item.dart';
import '../../../shared/widgets/undo_snackbar.dart';

/// 프로젝트별 태스크 목록.
///
/// AppBar: 프로젝트 컬러 배경 + 흰 타이틀 (MS Todo 패턴)
/// DnD: order 필드 업데이트
class ProjectTaskView extends ConsumerStatefulWidget {
  const ProjectTaskView({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<ProjectTaskView> createState() => _ProjectTaskViewState();
}

class _ProjectTaskViewState extends ConsumerState<ProjectTaskView> {
  List<Task>? _optimisticActive;

  Color get _projectColor {
    final hex = widget.project.color;
    if (hex == null) return AppColors.projectBlue;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.projectBlue;
    }
  }

  void _onReorder(List<Task> active, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final items = [...active];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _optimisticActive = items);

    final prevOrder = newIndex > 0 ? items[newIndex - 1].order : null;
    final nextOrder =
        newIndex < items.length - 1 ? items[newIndex + 1].order : null;

    final newOrder = _computeOrder(prevOrder, nextOrder);
    final repo = ref.read(taskRepositoryProvider);

    final needsRebalance = prevOrder != null &&
        nextOrder != null &&
        (nextOrder - prevOrder).abs() < 1e-10;

    if (needsRebalance) {
      await repo.rebalanceOrder(items);
    } else {
      await repo.updateOrder(moved.id, newOrder);
    }

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
    final tasksAsync = ref.watch(_projectTasksProvider(widget.project.id));
    final color = _projectColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: color,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.project.name,
                style: AppTextStyles.title(color: Colors.white),
              ),
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 48, 14),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: () => _showMoreMenu(context),
              ),
            ],
          ),
        ],
        body: tasksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, st) => Center(
            child: Text(e.toString(),
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          data: (tasks) {
            final active = _optimisticActive ??
                tasks.where((t) => !t.completed).toList();
            final completed = tasks.where((t) => t.completed).toList();

            return ReorderableListView(
              onReorder: (o, n) => _onReorder(active, o, n),
              proxyDecorator: (child, index, anim) => AnimatedBuilder(
                animation: anim,
                builder: (context, child) => Material(
                  elevation: 4 * anim.value,
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
                child: child,
              ),
              footer: Column(
                children: [
                  if (completed.isNotEmpty)
                    CompletedSection(
                      tasks: completed,
                      onToggleComplete: (t) => _toggleComplete(t),
                      onTaskTap: (t) => TaskDetailSheet.show(context, t),
                      onToggleFocus: (t) => ref
                          .read(taskRepositoryProvider)
                          .setFocused(t, isFocused: !t.isFocused),
                      projectColor: color,
                    ),
                  const SizedBox(height: 80),
                ],
              ),
              children: active
                  .map((task) => TaskListItem(
                        key: ValueKey(task.id),
                        task: task,
                        onToggleComplete: () => _toggleComplete(task),
                        onTap: () => TaskDetailSheet.show(context, task),
                        onToggleFocus: () => ref
                            .read(taskRepositoryProvider)
                            .setFocused(task, isFocused: !task.isFocused),
                        projectColor: color,
                      ))
                  .toList(),
            );
          },
        ),
      ),
      bottomSheet: QuickAddBar(
        hintText: '${widget.project.name}에 추가',
        onAdd: (title) {
          final tasks =
              ref.read(_projectTasksProvider(widget.project.id)).valueOrNull ??
                  [];
          final maxOrder =
              tasks.isEmpty ? 0.0 : tasks.map((t) => t.order).reduce(max);
          ref.read(taskRepositoryProvider).createTask(
                title: title,
                order: maxOrder + 1000.0,
                projectId: widget.project.id,
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

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _ProjectMoreMenu(
        project: widget.project,
        onDeleted: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _projectTasksProvider =
    StreamProvider.autoDispose.family<List<Task>, String>(
  (ref, projectId) {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.watchActiveTasks().map(
          (tasks) => tasks.where((t) => t.projectId == projectId).toList(),
        );
  },
);

// ---------------------------------------------------------------------------
// 프로젝트 더보기 메뉴
// ---------------------------------------------------------------------------

class _ProjectMoreMenu extends ConsumerStatefulWidget {
  const _ProjectMoreMenu({required this.project, required this.onDeleted});

  final Project project;
  final VoidCallback onDeleted;

  @override
  ConsumerState<_ProjectMoreMenu> createState() => _ProjectMoreMenuState();
}

class _ProjectMoreMenuState extends ConsumerState<_ProjectMoreMenu> {
  bool _editingName = false;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            if (_editingName)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style:
                            AppTextStyles.body(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _saveName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveName,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent),
                      child: Text('저장',
                          style: AppTextStyles.body(color: Colors.white)),
                    ),
                  ],
                ),
              )
            else
              _MenuItem(
                icon: Icons.edit_outlined,
                label: '이름 변경',
                onTap: () => setState(() => _editingName = true),
              ),
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: '삭제',
              color: AppColors.error,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == widget.project.name) {
      setState(() => _editingName = false);
      return;
    }
    await ref
        .read(projectRepositoryProvider)
        .updateProject(widget.project.id, name: name);
    if (mounted) {
      setState(() => _editingName = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('프로젝트 삭제', style: AppTextStyles.headline()),
        content: Text(
          '"${widget.project.name}" 프로젝트를 삭제할까요?\n태스크는 Inbox로 이동됩니다.',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('삭제', style: AppTextStyles.body(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(projectRepositoryProvider)
          .deleteProject(widget.project.id);
      widget.onDeleted();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: AppTextStyles.body(color: c)),
      onTap: onTap,
    );
  }
}
