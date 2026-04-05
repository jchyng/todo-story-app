import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_story/data/repositories/task_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TaskRepository repo;

  const uid = 'test-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = TaskRepository(uid: uid, db: fakeFirestore);
  });

  test('미완료 탭 → 완료 상태 전환', () async {
    await repo.createTask(title: '기본 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;
    expect(task.completed, false);

    await repo.toggleComplete(task.id, completed: true);

    final completed = await repo.watchCompletedTasks().first;
    expect(completed.length, 1);
    expect(completed.first.completed, true);
    expect(completed.first.completedAt, isNotNull);
  });

  test('완료 탭 → 미완료 상태 복원', () async {
    await repo.createTask(title: '되돌릴 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.toggleComplete(task.id, completed: true);
    await repo.toggleComplete(task.id, completed: false);

    final completed = await repo.watchCompletedTasks().first;
    expect(completed, isEmpty);

    final active = await repo.watchActiveTasks().first;
    expect(active.first.completed, false);
    expect(active.first.completedAt, isNull);
  });

  test('완료 → 미완료 → 완료 연속 탭 → 최종 완료 상태 정합성', () async {
    await repo.createTask(title: '연속 탭 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final id = tasks.first.id;

    await repo.toggleComplete(id, completed: true);
    await repo.toggleComplete(id, completed: false);
    await repo.toggleComplete(id, completed: true);

    final completed = await repo.watchCompletedTasks().first;
    expect(completed.length, 1);
    expect(completed.first.completed, true);
    expect(completed.first.completedAt, isNotNull);
  });
}
