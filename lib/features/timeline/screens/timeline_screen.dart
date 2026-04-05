import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/providers/repository_providers.dart';

/// Timeline 화면 — 완료된 태스크 월별 그룹핑.
///
/// 월 헤더: Fraunces 세리프 (DESIGN.md 차별화 포인트)
/// 태스크 행: 프로젝트 컬러 도트 + 제목 + 완료일 (Geist Mono)
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(_completedTasksProvider);
    final projectsAsync = ref.watch(_allProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('타임라인', style: AppTextStyles.title()),
        actions: [
          completedAsync.when(
            data: (tasks) => IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.textMuted),
              tooltip: '공유',
              onPressed: tasks.isEmpty
                  ? null
                  : () => _share(tasks, projectsAsync.valueOrNull ?? []),
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: completedAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTextStyles.body(color: AppColors.textMuted)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                '완료된 할 일이 없습니다',
                style: AppTextStyles.body(color: AppColors.textMuted),
              ),
            );
          }
          final projects = projectsAsync.valueOrNull ?? [];
          final grouped = _groupByMonth(tasks);
          return _TimelineList(grouped: grouped, projects: projects);
        },
      ),
    );
  }

  /// completedAt 기준 연/월로 그룹핑. 최신 월이 먼저.
  static Map<String, List<Task>> _groupByMonth(List<Task> tasks) {
    final map = <String, List<Task>>{};
    for (final task in tasks) {
      final dt = task.completedAt ?? task.updatedAt;
      final key = _monthKey(dt);
      map.putIfAbsent(key, () => []).add(task);
    }
    return map;
  }

  static String _monthKey(DateTime dt) => '${dt.year}/${dt.month}';

  static String _monthLabel(String key) {
    final parts = key.split('/');
    return '${parts[0]}년 ${parts[1]}월';
  }

  void _share(List<Task> tasks, List<Project> projects) {
    final sb = StringBuffer();
    sb.writeln('TodoStory 타임라인');
    sb.writeln();

    final grouped = _groupByMonth(tasks);
    for (final entry in grouped.entries) {
      sb.writeln('── ${_monthLabel(entry.key)} ──');
      for (final task in entry.value) {
        final dt = task.completedAt ?? task.updatedAt;
        final dateStr =
            '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
        sb.writeln('✓ ${task.title}  $dateStr');
      }
      sb.writeln();
    }

    Share.share(sb.toString().trim());
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _completedTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchCompletedTasks();
});

final _allProjectsProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects();
});

// ---------------------------------------------------------------------------
// 리스트 위젯
// ---------------------------------------------------------------------------

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.grouped, required this.projects});

  final Map<String, List<Task>> grouped;
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[];

    for (final entry in grouped.entries) {
      // 월 헤더
      slivers.add(
        SliverToBoxAdapter(
          child: _MonthHeader(
            label: TimelineScreen._monthLabel(entry.key),
            count: entry.value.length,
          ),
        ),
      );

      // 태스크 행 목록
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = entry.value[index];
              final project = projects
                  .where((p) => p.id == task.projectId)
                  .firstOrNull;
              return _TimelineTaskRow(task: task, project: project);
            },
            childCount: entry.value.length,
          ),
        ),
      );

      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

    return CustomScrollView(slivers: slivers);
  }
}

// ---------------------------------------------------------------------------
// 월 헤더
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label,
              style: AppTextStyles.timelineMonth(color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Text(
            '$count개',
            style: AppTextStyles.mono(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 태스크 행
// ---------------------------------------------------------------------------

class _TimelineTaskRow extends StatelessWidget {
  const _TimelineTaskRow({required this.task, required this.project});

  final Task task;
  final Project? project;

  Color get _dotColor {
    final hex = project?.color;
    if (hex == null) return AppColors.accent;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = task.completedAt ?? task.updatedAt;
    final dateStr =
        '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          // 프로젝트 컬러 도트
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // 제목
          Expanded(
            child: Text(
              task.title,
              style: AppTextStyles.body(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 완료일 (Geist Mono)
          Text(dateStr, style: AppTextStyles.mono(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
