import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/providers/repository_providers.dart';

/// 휴지통 뷰 — deletedAt != null 태스크 목록.
///
/// 각 항목: 제목 + 삭제일 + [복원] [영구 삭제] 버튼
/// AppBar 우측: 전체 비우기 버튼 (태스크 있을 때만)
class TrashView extends ConsumerWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_trashTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('휴지통', style: AppTextStyles.title()),
        actions: [
          tasksAsync.whenData((tasks) => tasks).valueOrNull?.isNotEmpty == true
              ? TextButton(
                  onPressed: () => _confirmEmptyTrash(
                      context, ref, tasksAsync.valueOrNull ?? []),
                  child: Text('전체 비우기',
                      style: AppTextStyles.body(color: AppColors.error)),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.body(color: AppColors.textMuted)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                '휴지통이 비어있습니다',
                style: AppTextStyles.body(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TrashTaskRow(
                task: task,
                onRestore: () => _restore(context, ref, task),
                onDelete: () => _confirmDelete(context, ref, task),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restore(
      BuildContext context, WidgetRef ref, Task task) async {
    await ref.read(taskRepositoryProvider).restoreFromTrash(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('"${task.title}" 복원됨', style: AppTextStyles.body()),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('영구 삭제', style: AppTextStyles.headline()),
        content: Text(
          '"${task.title}"을(를) 영구적으로 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('삭제', style: AppTextStyles.body(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(taskRepositoryProvider).deletePermanently(task.id);
    }
  }

  Future<void> _confirmEmptyTrash(
      BuildContext context, WidgetRef ref, List<Task> tasks) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('휴지통 비우기', style: AppTextStyles.headline()),
        content: Text(
          '${tasks.length}개 항목을 모두 영구적으로 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('전체 삭제',
                style: AppTextStyles.body(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(taskRepositoryProvider);
      for (final task in tasks) {
        await repo.deletePermanently(task.id);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _trashTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTrashTasks();
});

// ---------------------------------------------------------------------------
// 태스크 행
// ---------------------------------------------------------------------------

class _TrashTaskRow extends StatelessWidget {
  const _TrashTaskRow({
    required this.task,
    required this.onRestore,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deletedAt = task.deletedAt;
    final dateLabel = deletedAt != null ? _formatDate(deletedAt) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 삭제 아이콘
          const Icon(Icons.delete_outline_rounded,
              size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          // 제목 + 날짜
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.body(color: AppColors.textMuted).copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateLabel,
                      style: AppTextStyles.label(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          // 복원 버튼
          IconButton(
            icon: const Icon(Icons.restore_rounded,
                size: 20, color: AppColors.accent),
            tooltip: '복원',
            onPressed: onRestore,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // 영구 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined,
                size: 20, color: AppColors.error),
            tooltip: '영구 삭제',
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '오늘 삭제됨';
    if (diff.inDays == 1) return '어제 삭제됨';
    if (diff.inDays < 7) return '${diff.inDays}일 전 삭제됨';
    return '${dt.month}/${dt.day} 삭제됨';
  }
}
