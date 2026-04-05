import 'package:flutter_test/flutter_test.dart';
import 'package:todo_story/core/utils/repeat_date_calculator.dart';
import 'package:todo_story/data/models/task_model.dart';

void main() {
  group('nextDueDate — day', () {
    test('매일 반복: 1일 후', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 1, unit: 'day');
      expect(nextDueDate(config, from), DateTime(2026, 4, 6));
    });

    test('3일마다 반복', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 3, unit: 'day');
      expect(nextDueDate(config, from), DateTime(2026, 4, 8));
    });

    test('월말 → 월 넘기기', () {
      final from = DateTime(2026, 4, 30);
      final config = const RepeatConfig(frequency: 1, unit: 'day');
      expect(nextDueDate(config, from), DateTime(2026, 5, 1));
    });
  });

  group('nextDueDate — week (weekDays 없음)', () {
    test('매주 반복: 7일 후', () {
      final from = DateTime(2026, 4, 5); // 일요일
      final config = const RepeatConfig(frequency: 1, unit: 'week');
      expect(nextDueDate(config, from), DateTime(2026, 4, 12));
    });

    test('2주마다 반복: 14일 후', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 2, unit: 'week');
      expect(nextDueDate(config, from), DateTime(2026, 4, 19));
    });
  });

  group('nextDueDate — week (weekDays 있음)', () {
    // 2026-04-05 = 일요일 (0)
    test('월~금 반복, 일요일 기준 → 다음 월요일', () {
      final from = DateTime(2026, 4, 5); // 일(0)
      final config = const RepeatConfig(
        frequency: 1,
        unit: 'week',
        weekDays: [1, 2, 3, 4, 5], // 월~금
      );
      expect(nextDueDate(config, from), DateTime(2026, 4, 6)); // 월요일
    });

    test('월/수/금 반복, 월요일 기준 → 다음 수요일', () {
      final from = DateTime(2026, 4, 6); // 월(1)
      final config = const RepeatConfig(
        frequency: 1,
        unit: 'week',
        weekDays: [1, 3, 5], // 월/수/금
      );
      expect(nextDueDate(config, from), DateTime(2026, 4, 8)); // 수요일
    });

    test('월/수/금 반복, 금요일 기준 → 다음 주 월요일', () {
      final from = DateTime(2026, 4, 10); // 금(5)
      final config = const RepeatConfig(
        frequency: 1,
        unit: 'week',
        weekDays: [1, 3, 5], // 월/수/금
      );
      expect(nextDueDate(config, from), DateTime(2026, 4, 13)); // 다음 주 월요일
    });

    test('토요일만 반복, 토요일 기준 → 다음 주 토요일', () {
      final from = DateTime(2026, 4, 11); // 토(6)
      final config = const RepeatConfig(
        frequency: 1,
        unit: 'week',
        weekDays: [6], // 토
      );
      expect(nextDueDate(config, from), DateTime(2026, 4, 18));
    });
  });

  group('nextDueDate — month', () {
    test('매월 반복: 같은 날', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 1, unit: 'month');
      expect(nextDueDate(config, from), DateTime(2026, 5, 5));
    });

    test('2개월마다', () {
      final from = DateTime(2026, 1, 15);
      final config = const RepeatConfig(frequency: 2, unit: 'month');
      expect(nextDueDate(config, from), DateTime(2026, 3, 15));
    });

    test('1월 31일 + 1개월 → 2월 28일 (말일 조정)', () {
      final from = DateTime(2026, 1, 31);
      final config = const RepeatConfig(frequency: 1, unit: 'month');
      expect(nextDueDate(config, from), DateTime(2026, 2, 28));
    });

    test('1월 31일 + 1개월 → 2월 29일 (윤년)', () {
      final from = DateTime(2024, 1, 31);
      final config = const RepeatConfig(frequency: 1, unit: 'month');
      expect(nextDueDate(config, from), DateTime(2024, 2, 29));
    });

    test('12월 + 1개월 → 다음 해 1월', () {
      final from = DateTime(2026, 12, 10);
      final config = const RepeatConfig(frequency: 1, unit: 'month');
      expect(nextDueDate(config, from), DateTime(2027, 1, 10));
    });
  });

  group('nextDueDate — year', () {
    test('매년 반복', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 1, unit: 'year');
      expect(nextDueDate(config, from), DateTime(2027, 4, 5));
    });

    test('2년마다 반복', () {
      final from = DateTime(2026, 6, 1);
      final config = const RepeatConfig(frequency: 2, unit: 'year');
      expect(nextDueDate(config, from), DateTime(2028, 6, 1));
    });

    test('2월 29일(윤년) + 1년 → 2월 28일', () {
      final from = DateTime(2024, 2, 29);
      final config = const RepeatConfig(frequency: 1, unit: 'year');
      expect(nextDueDate(config, from), DateTime(2025, 2, 28));
    });
  });

  group('nextDueDate — 잘못된 unit', () {
    test('알 수 없는 unit → ArgumentError', () {
      final from = DateTime(2026, 4, 5);
      final config = const RepeatConfig(frequency: 1, unit: 'hour');
      expect(() => nextDueDate(config, from), throwsArgumentError);
    });
  });
}
