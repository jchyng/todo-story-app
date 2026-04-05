import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../features/project/screens/project_task_view.dart';
import '../../../features/project/widgets/create_project_dialog.dart';
import '../../../features/task_detail/task_detail_sheet.dart';
import '../../../features/timeline/screens/timeline_screen.dart';
import '../../../shared/providers/repository_providers.dart';
import '../views/inbox_view.dart';
import '../views/today_view.dart';
import '../views/trash_view.dart';
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

  Project? get _selectedProject {
    if (_selectedProjectId == null) return null;
    final projects = ref.watch(_allProjectsProvider).valueOrNull ?? [];
    return projects.where((p) => p.id == _selectedProjectId).firstOrNull;
  }

  String get _appBarTitle {
    if (_selectedProject != null) return _selectedProject!.name;
    switch (_currentView) {
      case HomeView.inbox:
        return 'Inbox';
      case HomeView.today:
        return '오늘';
      case HomeView.upcoming:
        return '예정';
      case HomeView.timeline:
        return '타임라인';
      case HomeView.trash:
        return '휴지통';
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(_allProjectsProvider).valueOrNull ?? [];
    final activeProjects = projects.where((p) => !p.isArchived).toList();
    final archivedProjects = projects.where((p) => p.isArchived).toList();
    final project = _selectedProject;
    final isToday =
        _currentView == HomeView.today && _selectedProjectId == null;
    // ProjectTaskView와 TimelineScreen은 자체 Scaffold를 가짐
    final isProjectView = project != null;
    final isTimeline =
        _currentView == HomeView.timeline && _selectedProjectId == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isToday || isProjectView || isTimeline
          ? null
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
        projects: activeProjects,
        archivedProjects: archivedProjects,
        selectedProjectId: _selectedProjectId,
        onProjectSelected: (id) => setState(() => _selectedProjectId = id),
        onCreateProject: () => CreateProjectDialog.show(context),
      ),
      body: _buildBody(project),
    );
  }

  Widget _buildBody(Project? project) {
    if (project != null) {
      return ProjectTaskView(project: project);
    }
    switch (_currentView) {
      case HomeView.inbox:
        return InboxView(onTaskTap: _openTaskDetail);
      case HomeView.today:
        return TodayView(onTaskTap: _openTaskDetail);
      case HomeView.upcoming:
        return UpcomingView(onTaskTap: _openTaskDetail);
      case HomeView.timeline:
        return const TimelineScreen();
      case HomeView.trash:
        return const TrashView();
    }
  }

  void _openTaskDetail(Task task) => TaskDetailSheet.show(context, task);
}

// ---------------------------------------------------------------------------
// Provider (화면 로컬)
// ---------------------------------------------------------------------------

final _allProjectsProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.watchProjects();
});

