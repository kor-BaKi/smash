import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/api/calendar_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/poll_model.dart';
import '../provider/auth_provider.dart';
import '../provider/poll_provider.dart';

class CalendarTabPage extends ConsumerStatefulWidget {
  const CalendarTabPage({super.key});

  @override
  ConsumerState<CalendarTabPage> createState() => _CalendarTabPageState();
}

class _CalendarTabPageState extends ConsumerState<CalendarTabPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _events = [];
  List<PollInfo> _polls = [];
  Map<int, int> _pollSlots = {};
  int _totalSlots = 0;
  bool _isLoading = true;

  static const double _kRowHeight = 110;
  static const double _kDateArea = 26;
  static const double _kItemHeight = 10;

  void _assignPollSlots() {
    // 기간 내림차순 정렬 후 슬롯 부여
    final sorted = List.generate(_polls.length, (i) => i)
      ..sort(
        (a, b) =>
            _getPollDuration(_polls[b]).compareTo(_getPollDuration(_polls[a])),
      );

    _pollSlots = {};
    for (int slot = 0; slot < sorted.length; slot++) {
      _pollSlots[sorted[slot]] = slot;
    }
    _totalSlots = _polls.length;
  }

  static const _pollColors = [
    AppColors.green,
    AppColors.coral,
    AppColors.lime,
    AppColors.accentViolet,
    AppColors.accentBlue,
  ];

  Color _getPollColor(int index) => _pollColors[index % _pollColors.length];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(pollProvider.notifier).loadPolls();
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await CalendarApi.getEvents(
        _focusedDay.year,
        _focusedDay.month,
      );
      setState(() {
        _events = events;
        _polls = ref.read(pollProvider).polls;
        _assignPollSlots();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDayDetailSheet(
    DateTime day,
    List<Map<String, dynamic>> events,
    List<PollInfo> polls,
  ) async {
    final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.month}월 ${day.day}일',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 임원 일정
            ...events.map(
              (event) => Container(
                // margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          if (event['memo'] != null &&
                              event['memo'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              event['memo'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isAdmin)
                      GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await CalendarApi.delete(event['id']);
                          await _loadEvents();
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.coral,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 투표 일정
            ...polls.map(
              (poll) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.green, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poll.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            poll.closedAt != null
                                ? '마감: ${poll.closedAt!.substring(0, 10)}'
                                : '진행중',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '투표',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events.where((e) {
      final date = DateTime.parse(e['date']);
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  int _getPollDuration(PollInfo poll) {
    final start = DateTime.parse(poll.createdAt);
    if (poll.closedAt == null) return 1;
    final end = DateTime.parse(poll.closedAt!);
    return end.difference(start).inDays + 1;
  }

  List<PollInfo> _getPollsForDay(DateTime day) {
    return _polls.where((poll) {
      final start = DateTime.parse(poll.createdAt);
      final startDate = DateTime(start.year, start.month, start.day);
      if (poll.closedAt == null) return isSameDay(startDate, day);
      final end = DateTime.parse(poll.closedAt!);
      final endDate = DateTime(end.year, end.month, end.day);
      return !day.isBefore(startDate) && !day.isAfter(endDate);
    }).toList();
  }

  List<({PollInfo poll, int index})> _getPollsOverDay(DateTime day) {
    final result = <({PollInfo poll, int index})>[];
    for (int i = 0; i < _polls.length; i++) {
      final poll = _polls[i];
      final start = DateTime.parse(poll.createdAt);
      final startDate = DateTime(start.year, start.month, start.day);
      if (poll.closedAt == null) {
        if (isSameDay(startDate, day)) result.add((poll: poll, index: i));
        continue;
      }
      final end = DateTime.parse(poll.closedAt!);
      final endDate = DateTime(end.year, end.month, end.day);
      if (!day.isBefore(startDate) && !day.isAfter(endDate)) {
        result.add((poll: poll, index: i));
      }
    }
    return result;
  }

  bool _isPollStart(PollInfo poll, DateTime day) {
    final start = DateTime.parse(poll.createdAt);
    return isSameDay(DateTime(start.year, start.month, start.day), day);
  }

  bool _isPollEnd(PollInfo poll, DateTime day) {
    if (poll.closedAt == null) return true;
    final end = DateTime.parse(poll.closedAt!);
    return isSameDay(DateTime(end.year, end.month, end.day), day);
  }

  bool _isWeekStart(DateTime day) => day.weekday == DateTime.sunday;
  bool _isWeekEnd(DateTime day) => day.weekday == DateTime.saturday;

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    final selectedDate = _selectedDay ?? _focusedDay;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '일정 추가',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: '제목',
                hintStyle: const TextStyle(color: AppColors.gray),
                filled: true,
                fillColor: AppColors.card2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memoController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: '메모 (선택)',
                hintStyle: const TextStyle(color: AppColors.gray),
                filled: true,
                fillColor: AppColors.card2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                if (titleController.text.isEmpty) return;
                try {
                  await CalendarApi.create(
                    titleController.text,
                    selectedDate.toIso8601String().substring(0, 10),
                    memoController.text.isEmpty ? null : memoController.text,
                  );
                  if (mounted) Navigator.pop(context);
                  await _loadEvents();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('일정 추가 실패')));
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '추가',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected, bool isToday) {
    final eventsForDay = _getEventsForDay(day);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    // 이 셀에 표시 가능한 최대 아이템 수
    final maxItems = ((_kRowHeight - _kDateArea) / _kItemHeight).floor();

    final itemWidgets = <Widget>[];

    // 투표 슬롯 (빈 슬롯도 항상 같은 높이 유지)
    for (int slot = 0; slot < _totalSlots; slot++) {
      if (itemWidgets.length >= maxItems) break;

      final pollIndex = _pollSlots.entries
          .where((e) => e.value == slot)
          .map((e) => e.key)
          .firstOrNull;

      if (pollIndex == null) {
        itemWidgets.add(const SizedBox(height: _kItemHeight));
        continue;
      }

      final poll = _polls[pollIndex];
      final start = DateTime.parse(poll.createdAt);
      final startDate = DateTime(start.year, start.month, start.day);
      DateTime? endDate;
      if (poll.closedAt != null) {
        final end = DateTime.parse(poll.closedAt!);
        endDate = DateTime(end.year, end.month, end.day);
      }

      final isInRange = endDate == null
          ? isSameDay(startDate, day)
          : !day.isBefore(startDate) && !day.isAfter(endDate);

      if (!isInRange) {
        // 조건 없이 항상 같은 높이 → 슬롯 정렬 유지
        itemWidgets.add(const SizedBox(height: _kItemHeight));
        continue;
      }

      final isStart = isSameDay(startDate, day) || _isWeekStart(day);
      final isEnd = endDate == null
          ? true
          : isSameDay(endDate, day) || _isWeekEnd(day);
      final showTitle = isSameDay(startDate, day) || _isWeekStart(day);
      final color = _getPollColor(pollIndex);

      itemWidgets.add(
        Container(
          height: _kItemHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.horizontal(
              left: isStart ? const Radius.circular(4) : Radius.zero,
              right: isEnd ? const Radius.circular(4) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.only(left: 3),
          alignment: Alignment.centerLeft,
          child: showTitle
              ? Text(
                  poll.title,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'BMJUA',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : null,
        ),
      );
    }

    // 임원 일정
    int hiddenCount = 0;
    for (final event in eventsForDay) {
      if (itemWidgets.length >= maxItems) {
        hiddenCount++;
        continue;
      }
      itemWidgets.add(
        Container(
          height: _kItemHeight,
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.only(left: 3),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                    fontFamily: 'BMJUA',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 넘친 개수 표시
    if (hiddenCount > 0 && itemWidgets.isNotEmpty) {
      itemWidgets.removeLast();
      itemWidgets.add(
        SizedBox(
          height: _kItemHeight,
          child: Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              '+${hiddenCount + 1}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.gray,
                fontFamily: 'BMJUA',
              ),
            ),
          ),
        ),
      );
    }

    // 셀 높이를 rowHeight로 강제 고정 + 클리핑
    return SizedBox(
      height: _kRowHeight,
      width: double.infinity,
      child: ClipRect(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _kDateArea,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: isSelected
                      ? const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        )
                      : isToday
                      ? BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BMJUA',
                      color: isSelected
                          ? AppColors.onPrimary
                          : isToday
                          ? AppColors.lime
                          : isWeekend
                          ? AppColors.coral
                          : AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            ...itemWidgets,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text(
                    '캘린더',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (isAdmin)
                    GestureDetector(
                      onTap: _showAddEventDialog,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 캘린더 (전체 화면 차지)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    )
                  : TableCalendar(
                      rowHeight: _kRowHeight,
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        final events = _getEventsForDay(selectedDay);
                        final polls = _getPollsForDay(selectedDay);
                        if (events.isNotEmpty || polls.isNotEmpty) {
                          _showDayDetailSheet(selectedDay, events, polls);
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadEvents();
                      },
                      locale: 'ko_KR',
                      daysOfWeekHeight: 28,
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day, false, false),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day, true, false),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day, false, true),
                        outsideBuilder: (context, day, focusedDay) =>
                            const SizedBox(),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        cellMargin: EdgeInsets.zero,
                        cellPadding: EdgeInsets.zero,
                        defaultTextStyle: const TextStyle(
                          color: AppColors.white,
                          fontFamily: 'BMJUA',
                        ),
                        weekendTextStyle: const TextStyle(
                          color: AppColors.coral,
                          fontFamily: 'BMJUA',
                        ),
                        outsideTextStyle: const TextStyle(
                          color: AppColors.darkGray,
                          fontFamily: 'BMJUA',
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'BMJUA',
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.white,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.white,
                        ),
                        decoration: const BoxDecoration(color: AppColors.bg),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                          fontFamily: 'BMJUA',
                        ),
                        weekendStyle: TextStyle(
                          color: AppColors.coral,
                          fontSize: 12,
                          fontFamily: 'BMJUA',
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
