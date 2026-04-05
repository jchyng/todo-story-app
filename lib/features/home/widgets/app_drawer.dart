import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../features/settings/settings_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../shared/providers/repository_providers.dart';

enum HomeView { inbox, today, upcoming, timeline, trash }

/// 사이드 드로어.
///
/// 프로젝트 목록은 DnD로 순서 변경 가능 (ReorderableListView).
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    required this.projects,
    required this.archivedProjects,
    this.selectedProjectId,
    this.onProjectSelected,
    this.onCreateProject,
  });

  final HomeView currentView;
  final void Function(HomeView) onViewChanged;
  final List<Project> projects;
  final List<Project> archivedProjects;
  final String? selectedProjectId;
  final void Function(String projectId)? onProjectSelected;
  final VoidCallback? onCreateProject;

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  List<Project>? _optimisticProjects;
  bool _archiveExpanded = false;
  bool _isRebalancing = false;

  void _onProjectReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final snapshot = [...widget.projects];
    final items = [...(widget.projects)];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _optimisticProjects = items);

    final prevOrder = newIndex > 0 ? items[newIndex - 1].order : null;
    final nextOrder =
        newIndex < items.length - 1 ? items[newIndex + 1].order : null;

    double newOrder;
    if (prevOrder == null && nextOrder == null) {
      newOrder = 1000.0;
    } else if (prevOrder == null) {
      newOrder = nextOrder! / 2;
    } else if (nextOrder == null) {
      newOrder = prevOrder + 1000.0;
    } else {
      newOrder = (prevOrder + nextOrder) / 2;
    }

    final repo = ref.read(projectRepositoryProvider);
    final needsRebalance = prevOrder != null &&
        nextOrder != null &&
        (nextOrder - prevOrder).abs() < 1e-10;

    if (needsRebalance) {
      setState(() => _isRebalancing = true);
      try {
        await repo.rebalanceOrder(items);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _optimisticProjects = snapshot;
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
      await repo.updateOrder(moved.id, newOrder);
    }

    if (mounted) setState(() => _optimisticProjects = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projects = _optimisticProjects ?? widget.projects;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 리밸런싱 진행 중 인디케이터
            if (_isRebalancing)
              LinearProgressIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                minHeight: 2,
              ),
            // 프로필 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person_rounded,
                            color: AppColors.accent, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user?.displayName ?? user?.email ?? '사용자',
                      style: AppTextStyles.body(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),

            // 특수 뷰
            _DrawerNavItem(
              icon: Icons.inbox_rounded,
              label: 'Inbox',
              selected: widget.currentView == HomeView.inbox &&
                  widget.selectedProjectId == null,
              onTap: () {
                widget.onViewChanged(HomeView.inbox);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.today_rounded,
              label: '오늘',
              selected: widget.currentView == HomeView.today &&
                  widget.selectedProjectId == null,
              onTap: () {
                widget.onViewChanged(HomeView.today);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.calendar_month_rounded,
              label: '예정',
              selected: widget.currentView == HomeView.upcoming &&
                  widget.selectedProjectId == null,
              onTap: () {
                widget.onViewChanged(HomeView.upcoming);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.timeline_rounded,
              label: '타임라인',
              selected: widget.currentView == HomeView.timeline &&
                  widget.selectedProjectId == null,
              onTap: () {
                widget.onViewChanged(HomeView.timeline);
                Navigator.of(context).pop();
              },
            ),

            // 프로젝트 섹션
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (projects.isNotEmpty || widget.onCreateProject != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '프로젝트',
                            style:
                                AppTextStyles.label(color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          if (widget.onCreateProject != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onCreateProject!();
                              },
                              child: const Icon(Icons.add_rounded,
                                  size: 18, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                  // 프로젝트 목록 (DnD)
                  Expanded(
                    child: projects.isEmpty
                        ? const SizedBox.shrink()
                        : ReorderableListView(
                            shrinkWrap: true,
                            onReorder: _onProjectReorder,
                            proxyDecorator:
                                (child, index, anim) => Material(
                              color: AppColors.surface,
                              child: child,
                            ),
                            children: projects.map((p) {
                              final color = p.color != null
                                  ? _hexToColor(p.color!)
                                  : AppColors.projectBlue;
                              final selected =
                                  widget.selectedProjectId == p.id;
                              return _DrawerNavItem(
                                key: ValueKey(p.id),
                                icon: Icons.circle,
                                iconColor: color,
                                iconSize: 10,
                                label: p.name,
                                selected: selected,
                                onTap: () {
                                  widget.onProjectSelected?.call(p.id);
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),

            // 보관된 프로젝트 섹션
            if (widget.archivedProjects.isNotEmpty) ...[
              const Divider(color: AppColors.divider, height: 1),
              InkWell(
                onTap: () =>
                    setState(() => _archiveExpanded = !_archiveExpanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Text('보관된 프로젝트',
                          style: AppTextStyles.label(color: AppColors.textMuted)),
                      const Spacer(),
                      Icon(
                        _archiveExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_archiveExpanded)
                ...widget.archivedProjects.map((p) {
                  final color = p.color != null
                      ? _hexToColor(p.color!)
                      : AppColors.projectBlue;
                  return _DrawerNavItem(
                    key: ValueKey('archived_${p.id}'),
                    icon: Icons.circle,
                    iconColor: color.withValues(alpha: 0.5),
                    iconSize: 10,
                    label: p.name,
                    selected: widget.selectedProjectId == p.id,
                    onTap: () {
                      widget.onProjectSelected?.call(p.id);
                      Navigator.of(context).pop();
                    },
                  );
                }),
            ],

            const Divider(color: AppColors.divider, height: 1),

            // 하단: Trash + 로그아웃
            _DrawerNavItem(
              icon: Icons.delete_outline_rounded,
              label: '휴지통',
              selected: widget.currentView == HomeView.trash &&
                  widget.selectedProjectId == null,
              onTap: () {
                widget.onViewChanged(HomeView.trash);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.settings_outlined,
              label: '설정',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _DrawerNavItem(
              icon: Icons.logout_rounded,
              label: '로그아웃',
              selected: false,
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.projectBlue;
    }
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor,
    this.iconSize = 20,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icon,
        size: iconSize,
        color: selected ? AppColors.accent : (iconColor ?? AppColors.textMuted),
      ),
      title: Text(
        label,
        style: AppTextStyles.body(
          color: selected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
