import 'package:intl/intl.dart';

/// 화면에 보여주는 한국어 날짜·시간 표기.
///
/// 표기 안의 공백은 모두 줄바꿈이 없는 공백(NBSP, U+00A0)이다.
/// 좁은 화면에서 "11월 / 11일 (수)" 처럼 중간에서 끊기지 않게 하려는 것이다.
///
/// 로케일 데이터가 필요하다: main()의 initializeDateFormatting('ko_KR') 이후에 쓴다.
class KoDateFormat {
  KoDateFormat._();

  static const String nbsp = ' ';
  static const String _locale = 'ko_KR';

  /// 11월 11일 (수). 올해가 아니면 연도를 붙인다: 2027년 1월 5일 (화)
  /// [now] 는 올해 판단 기준이며 테스트에서 고정할 때만 넘긴다.
  static String date(DateTime value, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final pattern = value.year == today.year ? 'M월 d일 (E)' : 'y년 M월 d일 (E)';
    return _withNbsp(DateFormat(pattern, _locale).format(value));
  }

  /// 오후 3:00. 0시대는 "오전 12:xx", 12시대는 "오후 12:xx" 이다.
  static String time(DateTime value) {
    return _withNbsp(DateFormat('a h:mm', _locale).format(value));
  }

  /// 11월 11일 (수) 오후 3:00 (날짜와 시간 사이도 줄바꿈이 없다)
  static String dateTime(DateTime value, {DateTime? now}) {
    return '${date(value, now: now)}$nbsp${time(value)}';
  }

  static String _withNbsp(String text) => text.replaceAll(' ', nbsp);
}
