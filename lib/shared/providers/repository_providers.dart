import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/task_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

part 'repository_providers.g.dart';

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading) throw const AsyncLoading<TaskRepository>();
  final user = auth.valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return TaskRepository(uid: user.uid);
}

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading) throw const AsyncLoading<ProjectRepository>();
  final user = auth.valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return ProjectRepository(uid: user.uid);
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading) throw const AsyncLoading<UserRepository>();
  final user = auth.valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return UserRepository(uid: user.uid);
}

/// 활성 태스크 공유 스트림 — Inbox / Today / Upcoming 뷰가 이 하나를 공유한다.
///
/// 각 뷰가 watchActiveTasks()를 개별 호출하면 Firestore onSnapshot 리스너가
/// 3개 생성된다. 이 provider를 공유하면 리스너 1개로 줄어든다.
@riverpod
Stream<List<Task>> activeTasksStream(ActiveTasksStreamRef ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchActiveTasks();
}
