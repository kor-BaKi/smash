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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await CalendarApi.getEvents(
        _focusedDay.year,
        _focusedDay.month,
      );
      await ref.read(pollProvider.notifier).loadPolls();
      setState(() {
        _events = events;
        _polls = ref.read(pollProvider).polls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<PollInfo> _getPollsForDay(DateTime day) {
    return _polls.where((poll) {
      final start = DateTime.parse(poll.createdAt);
      final startDate = DateTime(start.year, start.month, start.day);

      if (poll.closedAt == null) {
        return isSameDay(startDate, day);
      }

      final end = DateTime.parse(poll.closedAt!);
      final endDate = DateTime(end.year, end.month, end.day);

      return !day.isBefore(startDate) && !day.isAfter(endDate);
    }).toList();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events.where((e) {
      final date = DateTime.parse(e['date']);
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? _focusedDay;

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
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () async {
                  if (titleController.text.isEmpty) return;
                  try {
                    await CalendarApi.create(
                      titleController.text,
                      selectedDate.toIso8601String().substring(0, 10),
                      memoController.text.isEmpty
                          ? null
                          : memoController.text,
                    );
                    if (mounted) Navigator.pop(context);
                    await _loadEvents();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('일정 추가 실패')),
                      );
                    }
                  }
                },
                child: Container(
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
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            ),
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
                          color: Color(0xFF111111),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 캘린더
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadEvents();
              },
              eventLoader: (day) {
                return [..._getEventsForDay(day), ..._getPollsForDay(day)];
              },
              locale: 'ko_KR',
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(
                  color: AppColors.white,
                  fontFamily: 'BMJUA',
                ),
                weekendTextStyle: const TextStyle(
                  color: AppColors.coral,
                  fontFamily: 'BMJUA',
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'BMJUA',
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'BMJUA',
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                outsideTextStyle: const TextStyle(
                  color: AppColors.darkGray,
                  fontFamily: 'BMJUA',
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

            // 선택된 날짜 일정
            if (_selectedDay != null) ...[
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.lime,
                        ),
                      )
                    : (_getEventsForDay(_selectedDay!).isEmpty &&
                          _getPollsForDay(_selectedDay!).isEmpty)
                    ? const Center(
                        child: Text(
                          '일정이 없습니다',
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._getEventsForDay(_selectedDay!).map(
                            (event) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.lime,
                                      borderRadius: BorderRadius.circular(
                                        2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['title'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        if (event['memo'] != null &&
                                            event['memo']
                                                .toString()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
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
                                        await CalendarApi.delete(
                                          event['id'],
                                        );
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
                          ..._getPollsForDay(_selectedDay!).map(
                            (poll) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.green,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(
                                        2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          poll.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
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
                                      color: AppColors.green.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
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
            ],
          ],
        ),
      ),
    );
  }
}
