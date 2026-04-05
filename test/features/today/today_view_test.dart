// Today 뷰 DnD 동작 테스트.
//
// NOTE: _computeOrder, _isRebalancing 오버레이 같은 위젯 내부 상태 테스트는
// 현재 단계에서는 리포지토리 수준 검증으로 커버한다.
// 위젯 레벨 테스트(WidgetTester)는 Firebase 연결 후 통합 테스트에서 추가.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_story/data/repositories/task_repository.dart';

/// _computeOrder 로직 검증용 헬퍼 (today_view.dart의 private 메서드와 동일한 로직)
///
/// today_view.dart의 _computeOrder를 별도 유틸로 추출하지 않았으므로
/// 동일 로직을 테스트에서 직접 정의하여 계산식 정확성을 검증한다.
double computeOrder(double? prev, double? next) {
  if (prev == null && next == null) return 1000.0;
  if (prev == null) return next! / 2;
  if (next == null) return prev + 1000.0;
  return (prev + next) / 2;
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TaskRepository repo;

  const uid = 'test-uid';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = TaskRepository(uid: uid, db: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // _computeOrder 프랙셔널 인덱싱 수학 검증
  // ---------------------------------------------------------------------------

  group('_computeOrder 프랙셔널 인덱싱', () {
    test('A(1.0) ↔ B(3.0) 사이 삽입 → 중간값 2.0 반환', () {
      expect(computeOrder(1.0, 3.0), 2.0);
    });

    test('맨 앞 삽입 (prev=null, next=2.0) → 1.0 반환', () {
      expect(computeOrder(null, 2.0), 1.0);
    });

    test('맨 뒤 삽입 (prev=5.0, next=null) → prev + 1000.0 = 1005.0 반환', () {
      expect(computeOrder(5.0, null), 1005.0);
    });

    test('빈 목록 (prev=null, next=null) → 기본값 1000.0', () {
      expect(computeOrder(null, null), 1000.0);
    });

    test('gap < 1e-10 조건 감지: abs(next-prev) < 1e-10', () {
      const prev = 1.0;
      const next = prev + 5e-11; // 5e-11 < 1e-10
      final gap = (next - prev).abs();
      expect(gap < 1e-10, true, reason: 'gap이 1e-10 미만이어야 rebalance가 트리거됨');
    });

    test('정상 gap: abs(next-prev) >= 1e-10이면 rebalance 불필요', () {
      const prev = 1.0;
      const next = 3.0;
      final gap = (next - prev).abs();
      expect(gap < 1e-10, false, reason: '충분한 간격이면 rebalance 불필요');
    });
  });

  // ---------------------------------------------------------------------------
  // 리밸런싱 후 순서 원복 (rebalanceOrder Firestore 통합)
  // ---------------------------------------------------------------------------

  group('rebalanceOrder 리밸런싱', () {
    test('리밸런싱 전 순서 스냅샷 저장 후 Firestore 결과 검증', () async {
      // 간격이 거의 0에 가까운 태스크 3개 생성
      await repo.createTask(title: 'A', order: 1.0);
      await repo.createTask(title: 'B', order: 1.0 + 5e-11);
      await repo.createTask(title: 'C', order: 1.0 + 1e-10);

      final tasks = await repo.watchActiveTasks().first;
      expect(tasks.length, 3);

      // 스냅샷 저장 (today_view.dart의 rollback 패턴과 동일)
      final snapshot = [...tasks];

      // rebalanceOrder 실행
      await repo.rebalanceOrder(tasks);

      final rebalanced = await repo.watchActiveTasks().first;
      final orders = rebalanced.map((t) => t.order).toList()..sort();

      // 리밸런싱 후 간격이 충분히 벌어져야 함 (1.0, 2.0, 3.0)
      expect(orders, [1.0, 2.0, 3.0]);

      // 스냅샷 개수는 그대로
      expect(snapshot.length, rebalanced.length);
    });

    test('focusOrder 리밸런싱: order 필드 불변, focusOrder만 재분배', () async {
      await repo.createTask(title: 'X', order: 100.0);
      await repo.createTask(title: 'Y', order: 200.0);

      final tasks = await repo.watchActiveTasks().first;
      for (final t in tasks) {
        await repo.setFocused(t, isFocused: true);
      }

      // focusOrder를 거의 같게 만들기
      await repo.updateFocusOrder(tasks[0].id, 1.0);
      await repo.updateFocusOrder(tasks[1].id, 1.0 + 5e-11);

      final focused = await repo.watchActiveTasks().first;
      await repo.rebalanceOrder(focused, useFocusOrder: true);

      final result = await repo.watchActiveTasks().first;

      // order는 변경되지 않아야 함
      final orders = result.map((t) => t.order).toList()..sort();
      expect(orders, containsAll([100.0, 200.0]));

      // focusOrder는 재분배되어야 함
      final focusOrders =
          result.map((t) => t.focusOrder).whereType<double>().toList()..sort();
      expect(focusOrders, [1.0, 2.0]);
    });
  });
}
