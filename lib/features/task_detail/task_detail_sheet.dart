import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../shared/providers/repository_providers.dart';

/// 태스크 상세 바텀시트.
///
/// DraggableScrollableSheet로 올려서 펼칠 수 있다.
/// 호출: showModalBottomSheet(isScrollControlled: true, ...)
class TaskDetailSheet extends ConsumerStatefulWidget {
  const TaskDetailSheet({super.key, required this.task});

  final Task task;

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleCtrl = TextEditingController(text: _task.title);
    _notesCtrl = TextEditingController(text: _task.notes ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  Future<void> _saveTitle() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || title == _task.title) return;
    await _repo.updateTask(_task.id, {'title': title});
  }

  Future<void> _saveNotes() async {
    final notes = _notesCtrl.text.trim();
    if (notes == (_task.notes ?? '')) return;
    await _repo.updateTask(
      _task.id,
      {'notes': notes.isEmpty ? null : notes},
    );
  }

  Future<void> _toggleFocus() async {
    await _repo.setFocused(_task, isFocused: !_task.isFocused);
    setState(() => _task = _task.copyWith(isFocused: !_task.isFocused));
  }

  Future<void> _addSubtask(String title) async {
    final newSubtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      completed: false,
    );
    final updated = [..._task.subtasks, newSubtask];
    await _repo.updateTask(_task.id, {
      'subtasks': updated.map((s) => s.toMap()).toList(),
    });
    setState(() => _task = _task.copyWith(subtasks: updated));
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final updated = _task.subtasks.map((s) {
      return s.id == subtask.id ? Subtask(id: s.id, title: s.title, completed: !s.completed) : s;
    }).toList();
    await _repo.updateTask(_task.id, {
      'subtasks': updated.map((s) => s.toMap()).toList(),
    });
    setState(() => _task = _task.copyWith(subtasks: updated));
  }

  Future<void> _setDueDate(String? date) async {
    if (date == null) {
      await _repo.updateTask(_task.id, {'dueDate': null});
      setState(() => _task = _task.copyWith(clearDueDate: true));
    } else {
      await _repo.updateTask(_task.id, {'dueDate': date});
      setState(() => _task = _task.copyWith(dueDate: date));
    }
  }

  Future<void> _deleteTask() async {
    await _repo.moveToTrash(_task.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              _DragHandle(),
              // 스크롤 본문
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  children: [
                    // 제목 + 체크박스
                    _TitleSection(
                      task: _task,
                      controller: _titleCtrl,
                      onToggleComplete: () async {
                        await _repo.toggleComplete(
                          _task.id,
                          completed: !_task.completed,
                        );
                        setState(() => _task =
                            _task.copyWith(completed: !_task.completed));
                      },
                      onTitleSubmit: _saveTitle,
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    // 서브태스크
                    _SubtaskSection(
                      subtasks: _task.subtasks,
                      onToggle: _toggleSubtask,
                      onAdd: _addSubtask,
                    ),
                    const Divider(color: AppColors.divider, height: 1),
                    // 액션 카드 그룹
                    _ActionGroup(
                      children: [
                        _ActionTile(
                          icon: _task.isFocused
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          iconColor: _task.isFocused
                              ? AppColors.accent
                              : AppColors.textMuted,
                          label: '오늘 할 일',
                          trailing: _task.isFocused ? '켜짐' : null,
                          onTap: _toggleFocus,
                        ),
                        _ActionTile(
                          icon: Icons.calendar_today_outlined,
                          label: '기한',
                          trailing: _task.dueDate != null
                              ? _formatDate(_task.dueDate!)
                              : null,
                          onTap: () => _showDatePicker(context),
                        ),
                        _ActionTile(
                          icon: Icons.notifications_none_rounded,
                          label: '알림',
                          trailing: _task.reminderOffset != null
                              ? '${_task.reminderOffset}분 전'
                              : null,
                          onTap: () {}, // Phase 4에서 구현
                        ),
                        _ActionTile(
                          icon: Icons.repeat_rounded,
                          label: '반복',
                          trailing: _repeatLabel(_task.repeat),
                          onTap: () {}, // Phase 4에서 구현
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 메모
                    _NotesSection(
                      controller: _notesCtrl,
                      onSubmit: _saveNotes,
                    ),
                    const SizedBox(height: 8),
                    // 하단: 생성일 + 삭제
                    _Footer(
                      createdAt: _task.createdAt,
                      onDelete: _deleteTask,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final initial = _task.dueDate != null
        ? DateTime.tryParse(_task.dueDate!) ?? now
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    final str =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await _setDueDate(str);
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
      if (diff == 0) return '오늘';
      if (diff == 1) return '내일';
      if (diff == -1) return '어제';
      return '${d.month}/${d.day}';
    } catch (_) {
      return date;
    }
  }

  String? _repeatLabel(String? repeat) {
    switch (repeat) {
      case 'daily':
        return '매일';
      case 'weekdays':
        return '평일';
      case 'weekends':
        return '주말';
      case 'weekly':
        return '매주';
      case 'monthly':
        return '매월';
      case 'yearly':
        return '매년';
      case 'custom':
        return '사용자 지정';
      default:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// 하위 위젯
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({
    required this.task,
    required this.controller,
    required this.onToggleComplete,
    required this.onTitleSubmit,
  });

  final Task task;
  final TextEditingController controller;
  final VoidCallback onToggleComplete;
  final VoidCallback onTitleSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? AppColors.accent : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 제목 인라인 편집
          Expanded(
            child: TextField(
              controller: controller,
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onTitleSubmit(),
              onTapOutside: (_) => onTitleSubmit(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskSection extends StatefulWidget {
  const _SubtaskSection({
    required this.subtasks,
    required this.onToggle,
    required this.onAdd,
  });

  final List<Subtask> subtasks;
  final void Function(Subtask) onToggle;
  final void Function(String) onAdd;

  @override
  State<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends State<_SubtaskSection> {
  bool _showInput = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 기존 서브태스크 목록
        ...widget.subtasks.map((s) => _SubtaskTile(
              subtask: s,
              onToggle: () => widget.onToggle(s),
            )),
        // 단계 추가 버튼 / 입력
        if (_showInput)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const SizedBox(width: 34), // 체크박스 자리 맞춤
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: AppTextStyles.body(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '단계 이름',
                      hintStyle:
                          AppTextStyles.body(color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      final t = v.trim();
                      if (t.isNotEmpty) widget.onAdd(t);
                      _ctrl.clear();
                      setState(() => _showInput = false);
                    },
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: () => setState(() => _showInput = true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text('단계 추가',
                      style: AppTextStyles.body(color: AppColors.accent)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({required this.subtask, required this.onToggle});

  final Subtask subtask;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    subtask.completed ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: subtask.completed
                      ? AppColors.accent
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: subtask.completed
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtask.title,
                style: AppTextStyles.body(
                  color: subtask.completed
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ).copyWith(
                  decoration: subtask.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                color: AppColors.divider,
                height: 1,
                indent: 44,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: iconColor ?? AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style:
                      AppTextStyles.body(color: AppColors.textPrimary)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style:
                      AppTextStyles.body(color: AppColors.accent)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body(color: AppColors.textPrimary),
        maxLines: null,
        minLines: 3,
        decoration: InputDecoration(
          hintText: '메모',
          hintStyle: AppTextStyles.body(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        onTapOutside: (_) => onSubmit(),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.createdAt, required this.onDelete});

  final DateTime createdAt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '생성일: ${createdAt.month}월 ${createdAt.day}일',
            style: AppTextStyles.label(color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
