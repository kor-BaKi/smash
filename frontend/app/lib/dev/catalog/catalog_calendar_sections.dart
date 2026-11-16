import 'package:flutter/material.dart';

import '../../core/design/colors.dart';
import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

/// 카탈로그에서 "오늘"을 고정해야 모양이 매번 같다
final _fixedToday = DateTime(2026, 11, 16);

SmashCalendarPeriod _period(
  int sm,
  int sd,
  int em,
  int ed, {
  String title = '뒤풀이 장소',
  int color = 0,
  int sy = 2026,
  int ey = 2026,
  bool deadline = true,
}) => SmashCalendarPeriod(
  start: DateTime(sy, sm, sd),
  end: DateTime(ey, em, ed),
  title: title,
  colorIndex: color,
  endIsDeadline: deadline,
);

bool _eventsOn18And24(DateTime day) =>
    day.month == 11 && (day.day == 18 || day.day == 24);

SmashCalendar _calendar({
  DateTime? month,
  DateTime? selected,
  bool Function(DateTime)? hasEventOn,
  bool Function(DateTime)? isDayEnabled,
  List<DateTimeRange> ranges = const [],
  List<SmashCalendarPeriod>? periods,
  DateTime? first,
  DateTime? last,
}) => SmashCalendar(
  month: month ?? DateTime(2026, 11),
  selectedDay: selected,
  today: _fixedToday,
  onDaySelected: (_) {},
  onMonthChanged: (_) {},
  hasEventOn: hasEventOn,
  isDayEnabled: isDayEnabled,
  highlightRanges: ranges,
  highlightLabel: '선택 불가 기간',
  periods: periods,
  firstMonth: first,
  lastMonth: last,
);

/// 팔레트 6색이 모두 보이도록 서로 겹치지 않는 기간을 주마다 하나씩 놓는다
List<SmashCalendarPeriod> _paletteSample() => [
  for (var i = 0; i < SmashColors.pollBandColors.length; i++)
    SmashCalendarPeriod(
      start: DateTime(2026, 11, 1 + i * 4),
      end: DateTime(2026, 11, 3 + i * 4),
      title: '색 ${i + 1}번',
      colorIndex: i,
    ),
];

final calendarEntry = CatalogEntry(
  name: 'SmashCalendar',
  description:
      '한 달 달력. 행사는 숫자 아래 색 점 하나, 투표 기간은 두꺼운 띠(제목과 투표별 색)로 보인다. '
      '선택, 오늘, 선택 불가, 강조 기간은 색뿐 아니라 모양과 읽는 말로 구분한다. 좌우로 밀어도 달이 넘어간다.',
  states: [
    CatalogState('기본 (오늘 11월 16일 고정, 띠 자리 없음)', (_) => _calendar()),
    CatalogState(
      '행사 점만 (18일, 24일: 일정이 있는지 없는지만)',
      (_) => _calendar(hasEventOn: _eventsOn18And24),
    ),
    CatalogState(
      '선택한 날 (11월 20일)',
      (_) => _calendar(
        selected: DateTime(2026, 11, 20),
        hasEventOn: _eventsOn18And24,
      ),
    ),
    CatalogState(
      '투표 1개 (제목이 띠 안에 보임, 시작은 띄워 평평, 마감은 둥근 끝)',
      (_) => _calendar(periods: [_period(11, 17, 11, 20)]),
    ),
    CatalogState(
      '투표 2개 겹침 (줄 2개)',
      (_) => _calendar(
        periods: [
          _period(11, 16, 11, 21, title: '뒤풀이 장소', color: 0),
          _period(11, 18, 11, 24, title: '행사 날짜 정하기', color: 1),
        ],
      ),
    ),
    CatalogState(
      '투표 3개 겹침 (줄 2개 + 가려진 투표는 "+1")',
      (_) => _calendar(
        periods: [
          _period(11, 16, 11, 22, title: '뒤풀이 장소', color: 0),
          _period(11, 17, 11, 23, title: '행사 날짜 정하기', color: 1),
          _period(11, 18, 11, 20, title: '회식 메뉴', color: 2),
        ],
      ),
    ),
    CatalogState(
      '점 + 띠가 같은 날 (18일, 24일: 점은 숫자 아래, 띠는 그 아래)',
      (_) => _calendar(
        selected: DateTime(2026, 11, 18),
        hasEventOn: _eventsOn18And24,
        periods: [
          _period(11, 16, 11, 20, title: '뒤풀이 장소', color: 0),
          _period(11, 18, 11, 24, title: '행사 날짜 정하기', color: 3),
        ],
      ),
    ),
    CatalogState(
      '팔레트 6색 전부 (색 번호 1~6, 6보다 크면 순환)',
      (_) => _calendar(periods: _paletteSample()),
    ),
    CatalogState(
      '하루짜리 투표 (좁은 띠에서 제목 말줄임) + 마감일 없는 투표(생성일 하루, 읽을 때 "마감일" 아님)',
      (_) => _calendar(
        periods: [
          _period(11, 12, 11, 12, title: '오늘 저녁 메뉴 투표', color: 4),
          _period(11, 26, 11, 26, title: '마감 없는 투표', color: 5, deadline: false),
        ],
      ),
    ),
    CatalogState(
      '긴 제목 (한 줄 말줄임)',
      (_) => _calendar(
        periods: [
          _period(
            11,
            15,
            11,
            21,
            title: '다음 달 정기 활동 장소와 시간대 그리고 준비물을 한꺼번에 정하는 투표',
            color: 1,
          ),
        ],
      ),
    ),
    CatalogState(
      '달 경계와 주 경계 (10/28~11/3, 11/28~12/4: 주마다 제목이 다시 시작)',
      (_) => _calendar(
        periods: [
          _period(10, 28, 11, 3, title: '10월 말 정산', color: 2),
          _period(11, 28, 12, 4, title: '12월 모임 일정', color: 3),
        ],
      ),
    ),
    CatalogState(
      '강조 기간 + 지난 날짜 선택 불가',
      (_) => _calendar(
        isDayEnabled: (day) => !day.isBefore(_fixedToday),
        ranges: [
          DateTimeRange(
            start: DateTime(2026, 11, 22),
            end: DateTime(2026, 11, 25),
          ),
        ],
        periods: [_period(11, 20, 11, 27, title: '송년회 날짜', color: 0)],
      ),
    ),
    CatalogState(
      '첫 달/마지막 달 (이동 버튼 비활성)',
      (_) => _calendar(first: DateTime(2026, 11), last: DateTime(2026, 11)),
    ),
    CatalogState(
      '6주 달 + 투표 (2026년 8월)',
      (_) => _calendar(
        month: DateTime(2026, 8),
        hasEventOn: (day) => day.month == 8 && (day.day == 6 || day.day == 14),
        periods: [
          _period(7, 28, 8, 9, title: '여름 합숙 일정', color: 0),
          _period(8, 10, 8, 20, title: '개강 총회', color: 1),
          _period(8, 12, 8, 31, title: '신입 환영회 장소', color: 2),
          _period(8, 14, 8, 18, title: '회비 납부', color: 3),
          _period(8, 29, 9, 3, title: '2학기 시간표', color: 4),
        ],
      ),
    ),
    CatalogState(
      '폭 320 (좁은 화면)',
      (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 320,
          child: _calendar(
            hasEventOn: _eventsOn18And24,
            periods: [
              _period(11, 17, 11, 20, title: '뒤풀이 장소', color: 0),
              _period(11, 18, 11, 18, title: '하루', color: 1),
              _period(11, 18, 11, 22, title: '긴 제목의 투표 이름', color: 2),
            ],
          ),
        ),
      ),
    ),
    CatalogState(
      '띠 자리만 있고 투표가 없음 (칸 높이가 같다)',
      (_) => _calendar(periods: const []),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<({DateTime month, DateTime? day})>(
        initial: (month: DateTime(2026, 11), day: null),
        describe: (v) =>
            '${v.month.year}년 ${v.month.month}월, ${v.day == null ? "선택한 날 없음" : SmashCalendarMath.dayLabel(v.day!)}',
        builder: (context, v, onChanged) {
          DateTime d(int day, [int addMonths = 0]) =>
              DateTime(v.month.year, v.month.month + addMonths, day);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SmashCalendar(
                month: v.month,
                selectedDay: v.day,
                onDaySelected: (day) => onChanged((month: v.month, day: day)),
                onMonthChanged: (month) =>
                    onChanged((month: month, day: v.day)),
                hasEventOn: (day) => day.day % 9 == 0,
                isDayEnabled: (day) => day.weekday != DateTime.sunday,
                periods: [
                  SmashCalendarPeriod(
                    start: d(5),
                    end: d(12),
                    title: '뒤풀이 장소',
                    colorIndex: 0,
                  ),
                  SmashCalendarPeriod(
                    start: d(10),
                    end: d(20),
                    title: '행사 날짜 정하기',
                    colorIndex: 1,
                  ),
                  SmashCalendarPeriod(
                    start: d(11),
                    end: d(14),
                    title: '회식 메뉴',
                    colorIndex: 2,
                  ),
                  SmashCalendarPeriod(
                    start: d(18),
                    end: d(3, 1),
                    title: '다음 달로 이어지는 투표',
                    colorIndex: 3,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: SmashSpacing.sm),
                child: Text(
                  '일요일은 선택할 수 없고, 9·18·27일에 행사 점이 있다. 투표 기간 띠 4개가 겹쳐 있다. 좌우로 밀어도 달이 넘어간다',
                  style: SmashText.caption,
                ),
              ),
            ],
          );
        },
      ),
    ),
  ],
);
