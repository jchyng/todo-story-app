import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../shared/providers/auth_provider.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);

      // 아직 Firebase 인증 상태 로딩 중 → 리다이렉트 없음
      if (auth.isLoading) return null;

      final loggedIn = auth.value != null;
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/';
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
    ],
  );
}

/// authProvider 변경을 GoRouter의 refreshListenable에 연결한다.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(RouterRef ref) {
    ref.listen(authProvider, (prev, next) => notifyListeners());
  }
}
