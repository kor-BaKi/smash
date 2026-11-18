import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/components.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

DioException _fakeOffline() =>
    DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError);

DioException _fakeServer() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 500,
        data: {'success': false, 'error': {'code': 'SERVER_ERROR', 'message': 'NullPointerException at Service.java:42'}},
      ),
    );

DioException _fakeBusiness() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 409,
        data: {'success': false, 'error': {'code': 'ALREADY_VOTED', 'message': '이미 투표했어요.'}},
      ),
    );

/// 카탈로그 안에서 높이가 정해진 칸을 만든다 (목록형 위젯은 높이가 필요하다)
Widget _box(Widget child, {double height = 280}) => SizedBox(height: height, child: child);

final skeletonEntry = CatalogEntry(
  name: 'SmashSkeleton',
  description: '불러오는 동안 자리를 잡는 회색 막대. 함께 깜빡이고, 동작 줄이기가 켜져 있으면 멈춘다. 스크린리더에는 "불러오는 중" 하나만.',
  states: [
    CatalogState('목록 4줄 (아바타 있음)', (_) => _box(const SmashSkeletonList(itemCount: 4), height: 300)),
    CatalogState('목록 3줄 (아바타 없음)', (_) => _box(const SmashSkeletonList(itemCount: 3, showAvatar: false), height: 220)),
    CatalogState(
      '막대 모양들 (직접 조합)',
      (_) => const SmashSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmashSkeleton(width: 200, height: 24),
            SizedBox(height: SmashSpacing.sm),
            SmashSkeleton(height: 16),
            SizedBox(height: SmashSpacing.xs),
            SmashSkeleton(width: 140, height: 16),
          ],
        ),
      ),
    ),
  ],
);

final emptyEntry = CatalogEntry(
  name: 'SmashEmpty',
  description: '비어 있는 화면. 무엇이 없는지와 무엇을 하면 되는지를 알려준다. scrollable이면 비어 있어도 당겨서 새로고침이 된다.',
  states: [
    CatalogState('제목만', (_) => _box(const SmashEmpty(title: '신청서가 없어요'), height: 220)),
    CatalogState(
      '설명 + 버튼',
      (_) => _box(
        SmashEmpty(
          title: '아직 활동이 없어요',
          message: '새 활동을 만들면 여기에 보여요.',
          actionLabel: '활동 만들기',
          onAction: () {},
        ),
        height: 300,
      ),
    ),
    CatalogState(
      '당겨서 새로고침 (아래로 당겨 보세요)',
      (_) => CatalogStateHost<int>(
        initial: 0,
        describe: (value) => '$value번 새로고침했어요',
        builder: (context, value, onChanged) => _box(
          RefreshIndicator(
            onRefresh: () async => onChanged(value + 1),
            child: const SmashEmpty(title: '비어 있어요', message: '아래로 당겨 보세요.', scrollable: true),
          ),
          height: 260,
        ),
      ),
    ),
    CatalogState(
      '긴 글',
      (_) => _box(
        const SmashEmpty(
          title: '이번 달에 참여한 활동이 아직 없어요',
          message: '활동에 참석하면 여기에 기록돼요. 참석한 날은 이월에도 반영돼요.',
          scrollable: true,
        ),
        height: 340,
      ),
    ),
  ],
);

final errorViewEntry = CatalogEntry(
  name: 'SmashErrorView',
  description: '화면 전체를 불러오지 못했을 때. 문구는 ErrorMessages가 정하고 예외 글자는 보이지 않는다. 인터넷 문제는 제목이 바뀐다.',
  states: [
    CatalogState('서버 오류 (서버의 내부 문구는 숨김)', (_) => _box(SmashErrorView(error: _fakeServer(), onRetry: () {}), height: 300)),
    CatalogState('인터넷 연결 없음', (_) => _box(SmashErrorView(error: _fakeOffline(), onRetry: () {}), height: 300)),
    CatalogState('서버가 준 사용자용 문구 (409)', (_) => _box(SmashErrorView(error: _fakeBusiness(), onRetry: () {}), height: 300)),
    CatalogState('알 수 없는 예외 (예외 글자 숨김)', (_) => _box(SmashErrorView(error: StateError('secret internal detail'), onRetry: () {}), height: 300)),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<int>(
        initial: 0,
        describe: (value) => '다시 시도를 $value번 눌렀어요',
        builder: (context, value, onChanged) => _box(
          SmashErrorView(error: _fakeServer(), onRetry: () => onChanged(value + 1)),
          height: 300,
        ),
      ),
    ),
  ],
);

enum _Demo { loading, data, empty, error, offline, refreshing, refreshFailed }

const _demoLabels = {
  _Demo.loading: '로딩',
  _Demo.data: '내용',
  _Demo.empty: '비어 있음',
  _Demo.error: '오류',
  _Demo.offline: '오프라인',
  _Demo.refreshing: '새로고침 중',
  _Demo.refreshFailed: '새로고침 실패',
};

AsyncValue<List<String>> _valueFor(_Demo demo) {
  const items = ['김민수', '이서연', '박지훈'];
  return switch (demo) {
    _Demo.loading => const AsyncLoading<List<String>>(),
    _Demo.data => const AsyncData(items),
    _Demo.empty => const AsyncData(<String>[]),
    _Demo.error => AsyncError<List<String>>(_fakeServer(), StackTrace.empty),
    _Demo.offline => AsyncError<List<String>>(_fakeOffline(), StackTrace.empty),
    _Demo.refreshing => const AsyncLoading<List<String>>().copyWithPrevious(const AsyncData(items)),
    _Demo.refreshFailed =>
      AsyncError<List<String>>(_fakeOffline(), StackTrace.empty).copyWithPrevious(const AsyncData(items)),
  };
}

final asyncViewEntry = CatalogEntry(
  name: 'SmashAsyncView',
  description: 'AsyncValue 하나를 로딩, 오류, 비어 있음, 내용으로 나눠 그린다. 이전 내용이 있으면 새로고침 중이나 실패해도 내용을 지키고 위에 안내만 붙인다.',
  states: [
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<_Demo>(
        initial: _Demo.data,
        describe: (value) => _demoLabels[value]!,
        builder: (context, value, onChanged) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: SmashSpacing.sm,
              children: [
                for (final demo in _Demo.values)
                  SmashChip(label: _demoLabels[demo]!, selected: value == demo, onPressed: () => onChanged(demo)),
              ],
            ),
            const SizedBox(height: SmashSpacing.sm),
            _box(
              SmashAsyncView<List<String>>(
                value: _valueFor(value),
                onRetry: () => onChanged(_Demo.loading),
                isEmpty: (items) => items.isEmpty,
                empty: const SmashEmpty(title: '아직 아무도 없어요', message: '회원이 들어오면 여기에 보여요.', scrollable: true),
                data: (context, items) => ListView(
                  // 안전 영역이 상자 안 목록의 위아래 여백으로 새지 않게 한다
                  padding: EdgeInsets.zero,
                  children: [
                    for (final name in items)
                      SmashListRow(title: name, leading: SmashAvatar(name: name)),
                  ],
                ),
              ),
              height: 360,
            ),
            Text('"다시 시도"를 누르면 로딩으로 바뀐다', style: SmashText.caption),
          ],
        ),
      ),
    ),
  ],
);
