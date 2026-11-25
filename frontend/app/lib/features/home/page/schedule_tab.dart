import 'package:flutter/material.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/spacing.dart';
import 'calendar_tab_page.dart';
import 'legacy_tab_frame.dart';
import 'poll_list_page.dart';

/// 일정 탭이 보여 주는 것: 달력 또는 투표
enum ScheduleView {
  calendar('달력'),
  polls('투표');

  const ScheduleView(this.label);

  final String label;
}

/// 일정 탭의 안쪽: 위의 "달력 | 투표" 전환과 고른 화면.
///
/// - 투표 탭이 없어져서 투표는 이 전환으로 닿는다. 달력과 투표 안쪽은 아직 옛 화면이고(어두운 바탕, 자기 앱바),
///   투표는 S4, 달력은 S5에서 새 디자인으로 바꾼다. 투표 보기에서는 옛 앱바가 셸 앱바 아래에 겹쳐 보인다 (임시)
/// - 고른 화면만 만든다 (전환하면 이전 화면은 사라지고 처음부터 다시 불러온다)
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({
    super.key,
    this.initialView = ScheduleView.calendar,
    this.calendarBuilder = _legacyCalendar,
    this.pollsBuilder = _legacyPolls,
  });

  final ScheduleView initialView;

  /// 달력 보기 만들기 (갤러리와 테스트에서 가짜 화면으로 바꿀 때만 넘긴다)
  final WidgetBuilder calendarBuilder;

  /// 투표 보기 만들기 (갤러리와 테스트에서 가짜 화면으로 바꿀 때만 넘긴다)
  final WidgetBuilder pollsBuilder;

  static Widget _legacyCalendar(BuildContext context) => const CalendarTabPage();
  static Widget _legacyPolls(BuildContext context) => const PollListPage();

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late ScheduleView _view = widget.initialView;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SmashSpacing.md,
            SmashSpacing.sm,
            SmashSpacing.md,
            SmashSpacing.sm,
          ),
          child: SmashSegmentedControl<ScheduleView>(
            semanticLabel: '일정 보기',
            segments: [
              for (final view in ScheduleView.values)
                SmashSegment(value: view, label: view.label),
            ],
            selected: _view,
            onChanged: (view) => setState(() => _view = view),
          ),
        ),
        Expanded(
          child: KeyedSubtree(
            key: ValueKey(_view),
            child: LegacyTabFrame(
              child: switch (_view) {
                ScheduleView.calendar => widget.calendarBuilder(context),
                ScheduleView.polls => widget.pollsBuilder(context),
              },
            ),
          ),
        ),
      ],
    );
  }
}
