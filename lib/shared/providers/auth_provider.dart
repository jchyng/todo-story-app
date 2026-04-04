import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Firebase Auth 상태 스트림.
/// User?가 null이면 비로그인, non-null이면 로그인 상태.
@riverpod
Stream<User?> auth(AuthRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

/// 현재 로그인된 User? (동기 접근용).
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authProvider).value;
}
