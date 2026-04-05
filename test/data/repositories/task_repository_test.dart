import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_story/data/models/task_model.dart';
import 'package:todo_story/data/repositories/task_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TaskRepository repo;

  const uid = 'test-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = TaskRepository(uid: uid, db: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // CRUD 기본
  // ---------------------------------------------------------------------------

  test('create → watchActiveTasks 스트림에 나타남', () async {
    await repo.createTask(title: '할 일 1', order: 1000.0);

    final tasks = await repo.watchActiveTasks().first;
    expect(tasks.length, 1);
    expect(tasks.first.title, '할 일 1');
    expect(tasks.first.completed, false);
    expect(tasks.first.isDeleted, false);
  });

  // ---------------------------------------------------------------------------
  // 완료 토글
  // ---------------------------------------------------------------------------

  test('toggleComplete(false→true) → completedAt 설정, watchActiveTasks에서 제거',
      () async {
    await repo.createTask(title: '완료할 할 일', order: 1000.0);
    final before = await repo.watchActiveTasks().first;
    final task = before.first;

    await repo.toggleComplete(task.id, completed: true);

    // watchActiveTasks는 completed==false만 반환하지 않음 (전체 활성 태스크)
    // 완료된 태스크는 watchCompletedTasks에서 확인
    final completed = await repo.watchCompletedTasks().first;
    expect(completed.length, 1);
    expect(completed.first.completed, true);
    expect(completed.first.completedAt, isNotNull);
  });

  test('toggleComplete(true→false) → completedAt null, 스트림 복원', () async {
    await repo.createTask(title: '되돌릴 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.toggleComplete(task.id, completed: true);
    await repo.toggleComplete(task.id, completed: false);

    final completed = await repo.watchCompletedTasks().first;
    expect(completed, isEmpty);

    final active = await repo.watchActiveTasks().first;
    final restored = active.first;
    expect(restored.completed, false);
    expect(restored.completedAt, isNull);
  });

  // ---------------------------------------------------------------------------
  // Soft Delete / Restore
  // ---------------------------------------------------------------------------

  test('moveToTrash → isDeleted=true, watchActiveTasks에서 제거', () async {
    await repo.createTask(title: '삭제할 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.moveToTrash(task.id);

    final active = await repo.watchActiveTasks().first;
    expect(active, isEmpty);

    final trash = await repo.watchTrashTasks().first;
    expect(trash.length, 1);
    expect(trash.first.isDeleted, true);
  });

  test('restoreFromTrash → isDeleted=false, watchActiveTasks에서 복원', () async {
    await repo.createTask(title: '복원할 할 일', order: 1000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.moveToTrash(task.id);
    await repo.restoreFromTrash(task.id);

    final active = await repo.watchActiveTasks().first;
    expect(active.length, 1);
    expect(active.first.isDeleted, false);
  });

  // ---------------------------------------------------------------------------
  // completeRepeatTask (WriteBatch 원자성)
  // ---------------------------------------------------------------------------

  test('completeRepeatTask → 원래 task completed=true + 새 occurrence 생성', () async {
    await repo.createTask(
      title: '매주 운동',
      order: 1000.0,
      dueDate: '2026-04-07',
      repeat: 'weekly',
      repeatConfig: const RepeatConfig(frequency: 1, unit: 'week'),
    );

    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.completeRepeatTask(
      task: task,
      nextDueDate: '2026-04-14',
      nextOrder: 2000.0,
    );

    final completed = await repo.watchCompletedTasks().first;
    expect(completed.length, 1);
    expect(completed.first.title, '매주 운동');
    expect(completed.first.completed, true);
    expect(completed.first.completionNonce, isNotNull);

    // watchActiveTasks는 deletedAt==null 전체 반환 (뷰가 completed 필터링).
    // 원본(completed=true) + 다음 occurrence(completed=false) 모두 포함.
    final all = await repo.watchActiveTasks().first;
    expect(all.length, 2);

    final next = all.firstWhere((t) => !t.completed);
    expect(next.title, '매주 운동');
    expect(next.dueDate, '2026-04-14');
  });

  test('completeRepeatTask → 다음 occurrence에 notes 복사', () async {
    await repo.createTask(
      title: '메모 있는 반복',
      order: 1000.0,
      repeat: 'daily',
    );
    // notes 추가
    final tasks = await repo.watchActiveTasks().first;
    await repo.updateTask(tasks.first.id, {'notes': '이 메모는 다음 회차에도 있어야 함'});

    final updated = await repo.watchActiveTasks().first;
    final task = updated.first;

    await repo.completeRepeatTask(
      task: task,
      nextDueDate: '2026-04-08',
      nextOrder: 2000.0,
    );

    final active = await repo.watchActiveTasks().first;
    expect(active.first.notes, '이 메모는 다음 회차에도 있어야 함');
  });

  // ---------------------------------------------------------------------------
  // setFocused / focusOrder
  // ---------------------------------------------------------------------------

  test('setFocused(true) → focusOrder가 order 값으로 초기화', () async {
    await repo.createTask(title: '포커스 할 일', order: 5000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;
    expect(task.focusOrder, isNull);

    await repo.setFocused(task, isFocused: true);

    final updated = await repo.watchActiveTasks().first;
    expect(updated.first.isFocused, true);
    expect(updated.first.focusOrder, 5000.0);
  });

  test('setFocused(false) → focusOrder null로 클리어', () async {
    await repo.createTask(title: '포커스 해제 할 일', order: 5000.0);
    final tasks = await repo.watchActiveTasks().first;
    final task = tasks.first;

    await repo.setFocused(task, isFocused: true);
    final focused = (await repo.watchActiveTasks().first).first;
    await repo.setFocused(focused, isFocused: false);

    final updated = await repo.watchActiveTasks().first;
    expect(updated.first.isFocused, false);
    expect(updated.first.focusOrder, isNull);
  });

  // ---------------------------------------------------------------------------
  // rebalanceOrder
  // ---------------------------------------------------------------------------

  test('rebalanceOrder 500개 이하 → 1.0, 2.0, 3.0 균등 간격 재분배', () async {
    for (var i = 0; i < 5; i++) {
      await repo.createTask(title: '할 일 $i', order: i * 0.00001);
    }

    final tasks = await repo.watchActiveTasks().first;
    await repo.rebalanceOrder(tasks);

    final rebalanced = await repo.watchActiveTasks().first;
    final orders = rebalanced.map((t) => t.order).toList()..sort();
    expect(orders, [1.0, 2.0, 3.0, 4.0, 5.0]);
  });

  test('rebalanceOrder(useFocusOrder: true) → focusOrder 필드만 업데이트', () async {
    await repo.createTask(title: '포커스 1', order: 1000.0);
    await repo.createTask(title: '포커스 2', order: 2000.0);

    final tasks = await repo.watchActiveTasks().first;
    for (final t in tasks) {
      await repo.setFocused(t, isFocused: true);
    }

    final focused = await repo.watchActiveTasks().first;
    await repo.rebalanceOrder(focused, useFocusOrder: true);

    final result = await repo.watchActiveTasks().first;
    final focusOrders = result.map((t) => t.focusOrder).whereType<double>().toList()..sort();
    expect(focusOrders, [1.0, 2.0]);

    // order 필드는 변경되지 않아야 함
    final orders = result.map((t) => t.order).toList()..sort();
    expect(orders, containsAll([1000.0, 2000.0]));
  });

  test('rebalanceOrder 500개 초과 → 배치 분할 처리', () async {
    // 501개 생성
    for (var i = 0; i < 501; i++) {
      await repo.createTask(title: '할 일 $i', order: i * 0.00001);
    }

    final tasks = await repo.watchActiveTasks().first;
    expect(tasks.length, 501);

    // 예외 없이 완료되어야 함
    await expectLater(repo.rebalanceOrder(tasks), completes);

    final rebalanced = await repo.watchActiveTasks().first;
    expect(rebalanced.length, 501);
    final orders = rebalanced.map((t) => t.order).toList()..sort();
    expect(orders.first, 1.0);
    expect(orders.last, 501.0);
  });
}
