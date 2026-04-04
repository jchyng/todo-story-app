import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/providers/repository_providers.dart';
import '../views/inbox_view.dart';
import '../views/today_view.dart';
import '../views/upcoming_view.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeView _currentView = HomeView.today;
  String? _selectedProjectId;

  String get _appBarTitle {
    if (_selectedProjectId != null) {
      final projects =
          ref.watch(_projectsProvider).valueOrNull ?? [];
      return projects
          .where((p) => p.id == _selectedProjectId)
          .map((p) => p.name)
          .firstOrNull ??
          '프로젝트';
    }
    switch (_currentView) {
      case HomeView.inbox:
        return 'Inbox';
      case HomeView.today:
        return '오늘';
      case HomeView.upcoming:
        return '예정';
      case HomeView.trash:
        return '휴지통';
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(_projectsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentView == HomeView.today
          ? null // Today 뷰는 그라디언트 헤더를 자체적으로 가짐
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(_appBarTitle, style: AppTextStyles.title()),
            ),
      drawer: AppDrawer(
        currentView: _currentView,
        onViewChanged: (view) => setState(() {
          _currentView = view;
          _selectedProjectId = null;
        }),
        projects: projects,
        selectedProjectId: _selectedProjectId,
        onProjectSelected: (id) => setState(() {
          _selectedProjectId = id;
        }),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 프로젝트 뷰 (Phase 3에서 구현)
    if (_selectedProjectId != null) {
      return Center(
        child: Text(
          'Phase 3에서 구현 예정',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
      );
    }

    switch (_currentView) {
      case HomeView.inbox:
        return InboxView(onTaskTap: _openTaskDetail);
      case HomeView.today:
        return TodayView(onTaskTap: _openTaskDetail);
      case HomeView.upcoming:
        return UpcomingView(onTaskTap: _openTaskDetail);
      case HomeView.trash:
        return _TrashPlaceholder();
    }
  }

  void _openTaskDetail(Task task) {
    // Phase 2 후반 — TaskDetailSheet 구현 시 연결
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailPlaceholder(task: task),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider (화면 로컬)
// ---------------------------------------------------------------------------

final _projectsProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects();
});

// ---------------------------------------------------------------------------
// Placeholder 위젯 (Phase 2~3에서 교체)
// ---------------------------------------------------------------------------

class _TrashPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Phase 2에서 구현 예정',
        style: AppTextStyles.body(color: AppColors.textMuted),
      ),
    );
  }
}

class _TaskDetailPlaceholder extends StatelessWidget {
  const _TaskDetailPlaceholder({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.title, style: AppTextStyles.headline()),
              const SizedBox(height: 8),
              Text(
                '상세 편집 — Phase 2에서 구현 예정',
                style: AppTextStyles.body(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
