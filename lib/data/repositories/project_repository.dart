import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/project_model.dart';

/// 프로젝트 Firestore CRUD + 실시간 스트림을 담당한다.
///
/// 컬렉션 경로: users/{uid}/projects/{projectId}
class ProjectRepository {
  final FirebaseFirestore _db;
  final String uid;

  ProjectRepository({required this.uid, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection('users').doc(uid).collection('projects');

  // ---------------------------------------------------------------------------
  // 실시간 스트림
  // ---------------------------------------------------------------------------

  /// 프로젝트 목록 스트림 (order 오름차순)
  Stream<List<Project>> watchProjects() {
    return _projects
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(Project.fromFirestore).toList());
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// 프로젝트 생성.
  /// order는 기존 프로젝트 수에 따라 자동 계산한다.
  Future<void> createProject({
    required String name,
    String? color,
  }) async {
    final snap = await _projects.orderBy('order', descending: true).limit(1).get();
    final lastOrder = snap.docs.isEmpty
        ? 0.0
        : (snap.docs.first.data()['order'] as num?)?.toDouble() ?? 0.0;

    final id = const Uuid().v4();
    await _projects.doc(id).set({
      'name': name,
      'color': color,
      'ownerId': uid,
      'memberIds': [uid],
      'memberCount': 1,
      'order': lastOrder + 1000.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 프로젝트 이름/색상 수정
  Future<void> updateProject(
    String id, {
    String? name,
    String? color,
    bool clearColor = false,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) data['name'] = name;
    if (clearColor) {
      data['color'] = null;
    } else if (color != null) {
      data['color'] = color;
    }
    await _projects.doc(id).update(data);
  }

  /// DnD 순서 변경 — order 필드만 수정 (fractional indexing)
  Future<void> updateOrder(String id, double newOrder) async {
    await _projects.doc(id).update({
      'order': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// order 정밀도 한계(gap < 1e-10) 시 전체 order 재설정 (1.0, 2.0, 3.0 ...)
  Future<void> rebalanceOrder(List<Project> projects) async {
    final batch = _db.batch();
    for (var i = 0; i < projects.length; i++) {
      batch.update(
        _projects.doc(projects[i].id),
        {'order': (i + 1) * 1000.0},
      );
    }
    await batch.commit();
  }

  /// 프로젝트 보관 (완료 상태로 전환, 삭제 아님).
  Future<void> archiveProject(String id) async {
    await _projects.doc(id).update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 보관된 프로젝트 복원 (활성 상태로 되돌리기).
  Future<void> unarchiveProject(String id) async {
    await _projects.doc(id).update({
      'isArchived': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 프로젝트 삭제
  /// 하위 tasks의 projectId 정리는 Cloud Function에서 처리한다.
  Future<void> deleteProject(String id) async {
    await _projects.doc(id).delete();
  }
}
