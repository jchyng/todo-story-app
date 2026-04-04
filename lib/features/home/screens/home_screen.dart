import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('오늘', style: AppTextStyles.title()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: '로그아웃',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              // GoRouter redirect가 자동으로 '/login'으로 이동
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.displayName ?? user?.email ?? '사용자',
                      style: AppTextStyles.body(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 8),
              // Phase 2에서 뷰 항목 추가 예정
              _DrawerItem(icon: Icons.inbox_rounded, label: 'Inbox'),
              _DrawerItem(icon: Icons.today_rounded, label: '오늘'),
              _DrawerItem(icon: Icons.calendar_month_rounded, label: '예정'),
            ],
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Phase 2에서 구현 예정',
          style: AppTextStyles.body(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted, size: 20),
      title: Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)),
      dense: true,
    );
  }
}
