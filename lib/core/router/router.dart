import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/repository_providers.dart';

part 'router.g.dart';

/// 온보딩 완료 여부 — Firestore users/{uid}.onboarding.googleTasksImportSeen
///
/// null: 로딩 중 또는 미로그인 (리다이렉트 판단 보류)
@riverpod
Stream<bool?> onboardingComplete(OnboardingCompleteRef ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || auth.valueOrNull == null) {
    return Stream.value(null);
  }
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUser().map((user) => user?.onboarding.googleTasksImportSeen);
}

@riverpod
GoRouter router(RouterRef ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);

      // 아직 Firebase 인증 상태 로딩 중 → 리다이렉트 없음
      if (auth.isLoading) return null;

      final loggedIn = auth.value != null;
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onOnboarding = loc == '/onboarding';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        // 온보딩 완료 여부 확인 (null = 로딩 중)
        final seen = ref.read(onboardingCompleteProvider).valueOrNull;
        if (seen == false) return '/onboarding';
        return '/';
      }
      if (loggedIn && !onOnboarding && !onLogin) {
        final seen = ref.read(onboardingCompleteProvider).valueOrNull;
        if (seen == false) return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        // TODO(Phase 4): OnboardingScreen 구현 후 교체
        builder: (context, state) => const _OnboardingPlaceholder(),
      ),
    ],
  );
}

/// auth + onboarding 변경을 GoRouter의 refreshListenable에 연결한다.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(RouterRef ref) {
    ref.listen(authProvider, (prev, next) => notifyListeners());
    ref.listen(onboardingCompleteProvider, (prev, next) => notifyListeners());
  }
}

/// Phase 4 OnboardingScreen이 구현될 때까지 사용하는 placeholder.
/// "Google Tasks에서 오셨나요?" + [가져오기] + [나중에] 버튼.
class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

