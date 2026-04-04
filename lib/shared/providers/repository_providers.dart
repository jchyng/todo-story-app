import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

part 'repository_providers.g.dart';

@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return TaskRepository(uid: user.uid);
}

@riverpod
ProjectRepository projectRepository(ProjectRepositoryRef ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return ProjectRepository(uid: user.uid);
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) throw Exception('Not authenticated');
  return UserRepository(uid: user.uid);
}
