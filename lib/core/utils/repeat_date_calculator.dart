import '../../data/models/task_model.dart';

/// 반복 태스크의 다음 기한을 계산하는 순수 함수 모듈.
///
/// [nextDueDate]는 [RepeatConfig]와 현재 기한 [from]을 받아
/// 다음 기한 [DateTime]을 반환한다.
///
/// 모든 함수는 부수효과 없는 순수 함수로, 단위 테스트가 쉽다.
DateTime nextDueDate(RepeatConfig config, DateTime from) {
  switch (config.unit) {
    case 'day':
      return from.add(Duration(days: config.frequency));

    case 'week':
      if (config.weekDays != null && config.weekDays!.isNotEmpty) {
        return _nextWeekDay(config.weekDays!, from);
      }
      return from.add(Duration(days: 7 * config.frequency));

    case 'month':
      return _addMonths(from, config.frequency);

    case 'year':
      return _addMonths(from, config.frequency * 12);

    default:
      throw ArgumentError('알 수 없는 반복 단위: ${config.unit}');
  }
}

/// [weekDays] 목록(0=일~6=토) 중 [from] 이후 가장 가까운 요일을 반환.
///
/// 같은 요일이라도 반드시 [from] 이후여야 하므로 최소 1일 이상 더한다.
DateTime _nextWeekDay(List<int> weekDays, DateTime from) {
  final sorted = [...weekDays]..sort();
  final fromWeekday = from.weekday % 7; // DateTime.weekday: 1(월)~7(일) → 0(일)~6(토)

  // from 이후의 같은 주에 해당하는 요일 찾기
  for (final wd in sorted) {
    final diff = (wd - fromWeekday + 7) % 7;
    if (diff > 0) {
      return from.add(Duration(days: diff));
    }
  }

  // 없으면 다음 주 첫 번째 요일
  final firstWd = sorted.first;
  final daysUntil = (firstWd - fromWeekday + 7) % 7;
  return from.add(Duration(days: daysUntil == 0 ? 7 : daysUntil));
}

/// 월 덧셈. 말일 초과 시 해당 월의 말일로 조정.
///
/// 예) 1월 31일 + 1개월 = 2월 28일(또는 29일)
DateTime _addMonths(DateTime date, int months) {
  var year = date.year;
  var month = date.month + months;

  while (month > 12) {
    month -= 12;
    year++;
  }
  while (month < 1) {
    month += 12;
    year--;
  }

  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day.clamp(1, lastDay);
  return DateTime(year, month, day);
}
