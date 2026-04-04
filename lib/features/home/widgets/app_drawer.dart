import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';

enum HomeView { inbox, today, upcoming, trash }

/// 사이드 드로어.
///
/// 구성: 프로필 헤더 / 특수 뷰(Inbox·Today·Upcoming·Trash) / 프로젝트 목록 / Settings
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    required this.projects,
    this.selectedProjectId,
    this.onProjectSelected,
  });

  final HomeView currentView;
  final void Function(HomeView) onViewChanged;
  final List<Project> projects;
  final String? selectedProjectId;
  final void Function(String projectId)? onProjectSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.accent,
                            size: 20,
                          )
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
              selected: currentView == HomeView.inbox && selectedProjectId == null,
              onTap: () {
                onViewChanged(HomeView.inbox);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.today_rounded,
              label: '오늘',
              selected: currentView == HomeView.today && selectedProjectId == null,
              onTap: () {
                onViewChanged(HomeView.today);
                Navigator.of(context).pop();
              },
            ),
            _DrawerNavItem(
              icon: Icons.calendar_month_rounded,
              label: '예정',
              selected: currentView == HomeView.upcoming && selectedProjectId == null,
              onTap: () {
                onViewChanged(HomeView.upcoming);
                Navigator.of(context).pop();
              },
            ),

            if (projects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '프로젝트',
                  style: AppTextStyles.label(color: AppColors.textMuted),
                ),
              ),
              // 프로젝트 목록
              ...projects.map((p) {
                final color = p.color != null
                    ? _hexToColor(p.color!)
                    : AppColors.projectBlue;
                return _DrawerNavItem(
                  icon: Icons.circle,
                  iconColor: color,
                  iconSize: 10,
                  label: p.name,
                  selected: selectedProjectId == p.id,
                  onTap: () {
                    onProjectSelected?.call(p.id);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],

            const Spacer(),
            const Divider(color: AppColors.divider, height: 1),

            // 하단: Trash + Settings + 로그아웃
            _DrawerNavItem(
              icon: Icons.delete_outline_rounded,
              label: '휴지통',
              selected: currentView == HomeView.trash && selectedProjectId == null,
              onTap: () {
                onViewChanged(HomeView.trash);
                Navigator.of(context).pop();
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
        color: selected
            ? AppColors.accent
            : (iconColor ?? AppColors.textMuted),
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
