import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

/// 개인 태스크의 Firestore CRUD + 실시간 스트림을 담당한다.
///
/// 컬렉션 경로: users/{uid}/tasks/{taskId}
class TaskRepository {
  final FirebaseFirestore _db;
  final String uid;

  TaskRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('users').doc(uid).collection('tasks');

  // ---------------------------------------------------------------------------
  // 실시간 스트림
  // ---------------------------------------------------------------------------

  /// 활성 태스크 스트림 (deletedAt == null)
  Stream<List<Task>> watchActiveTasks() {
    return _tasks
        .where('deletedAt', isNull: true)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(Task.fromFirestore).toList());
  }

  /// Trash 태스크 스트림 (deletedAt != null)
  Stream<List<Task>> watchTrashTasks() {
    return _tasks
        .where('deletedAt', isNull: false)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Task.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // 생성
  // ---------------------------------------------------------------------------

  Future<void> createTask({
    required String title,
    required double order,
    bool isFocused = false,
    String? projectId,
    String? dueDate,
    String? startTime,
    String? repeat,
    RepeatConfig? repeatConfig,
    int? reminderOffset,
  }) async {
    final id = const Uuid().v4();
    await _tasks.doc(id).set({
      'title': title,
      'completed': false,
      'isFocused': isFocused,
      'projectId': projectId,
      'subtasks': [],
      'order': order,
      'dueDate': dueDate,
      'startTime': startTime,
      'repeat': repeat,
      'repeatConfig': repeatConfig?.toMap(),
      'reminderOffset': reminderOffset,
      'deletedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // 완료 처리
  // ---------------------------------------------------------------------------

  /// 일반 태스크 완료/완료 취소.
  Future<void> toggleComplete(String taskId, {required bool completed}) async {
    await _tasks.doc(taskId).update({
      'completed': completed,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 반복 태스크 완료 처리 (WriteBatch로 원자적 실행).
  ///
  /// 두 작업을 하나의 WriteBatch에 묶어 atomicity를 보장한다:
  ///   1. 현재 태스크 완료 + completionNonce 설정
  ///   2. 다음 occurrence 태스크 생성 (parentNonce = completionNonce)
  ///
  /// Cloud Function은 parentNonce == completionNonce인 sibling이 이미 존재하면
  /// 중복 생성을 건너뛴다. 오프라인 double-complete 방지용.
  ///
  /// [task]는 완료할 반복 태스크.
  /// [nextDueDate]는 다음 회차의 마감일 ("YYYY-MM-DD").
  /// [nextOrder]는 다음 회차의 order 값 (Upcoming 뷰 최하단).
  Future<void> completeRepeatTask({
    required Task task,
    required String nextDueDate,
    required double nextOrder,
  }) async {
    final nonce = const Uuid().v4();
    final nextId = const Uuid().v4();

    final batch = _db.batch();

    // 1. 현재 태스크 완료
    batch.update(_tasks.doc(task.id), {
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'completionNonce': nonce,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. 다음 occurrence 생성
    batch.set(_tasks.doc(nextId), {
      'title': task.title,
      'completed': false,
      'isFocused': false,
      'projectId': task.projectId,
      'subtasks': [], // 서브태스크는 다음 회차에 초기화
      'order': nextOrder,
      'dueDate': nextDueDate,
      'startTime': task.startTime,
      'repeat': task.repeat,
      'repeatConfig': task.repeatConfig?.toMap(),
      'reminderOffset': task.reminderOffset,
      // parentNonce: Cloud Function이 이 값으로 중복 생성 여부를 검사한다
      'parentNonce': nonce,
      'deletedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // 수정
  // ---------------------------------------------------------------------------

  Future<void> updateTask(String taskId, Map<String, dynamic> fields) async {
    await _tasks.doc(taskId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// isFocused를 true로 설정할 때 focusOrder를 현재 order 값으로 초기화한다.
  ///
  /// Today DnD는 focusOrder만 수정한다.
  /// Inbox/Project DnD는 order만 수정한다.
  Future<void> setFocused(Task task, {required bool isFocused}) async {
    final update = <String, dynamic>{
      'isFocused': isFocused,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isFocused && task.focusOrder == null) {
      // 처음 Today에 추가될 때 order 값으로 초기화
      update['focusOrder'] = task.order;
    }

    if (!isFocused) {
      update['focusOrder'] = null;
    }

    await _tasks.doc(task.id).update(update);
  }

  // ---------------------------------------------------------------------------
  // 정렬 (Fractional Indexing)
  // ---------------------------------------------------------------------------

  /// Inbox/Project DnD: order 필드만 수정
  Future<void> updateOrder(String taskId, double newOrder) async {
    await _tasks.doc(taskId).update({
      'order': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Today DnD: focusOrder 필드만 수정
  Future<void> updateFocusOrder(String taskId, double newFocusOrder) async {
    await _tasks.doc(taskId).update({
      'focusOrder': newFocusOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 리밸런싱: 소수점 정밀도 한계 도달 시 order를 1.0, 2.0, 3.0... 으로 재설정.
  ///
  /// [tasks]는 현재 순서대로 정렬된 태스크 목록.
  /// [useFocusOrder]가 true이면 focusOrder를 리밸런싱한다 (Today 뷰용).
  Future<void> rebalanceOrder(
    List<Task> tasks, {
    bool useFocusOrder = false,
  }) async {
    const batchSize = 500; // Firestore WriteBatch 최대 500개
    for (var i = 0; i < tasks.length; i += batchSize) {
      final chunk = tasks.sublist(
        i,
        (i + batchSize).clamp(0, tasks.length),
      );
      final batch = _db.batch();
      for (var j = 0; j < chunk.length; j++) {
        final newOrder = (i + j + 1).toDouble();
        batch.update(_tasks.doc(chunk[j].id), {
          if (useFocusOrder) 'focusOrder': newOrder else 'order': newOrder,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // 삭제 (Soft Delete → Trash)
  // ---------------------------------------------------------------------------

  Future<void> moveToTrash(String taskId) async {
    await _tasks.doc(taskId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreFromTrash(String taskId) async {
    await _tasks.doc(taskId).update({
      'deletedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePermanently(String taskId) async {
    await _tasks.doc(taskId).delete();
  }
}
