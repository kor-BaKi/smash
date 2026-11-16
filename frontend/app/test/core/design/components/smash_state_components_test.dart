import 'dart:io' show SocketException;

import 'package:app/core/design/colors.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/error/error_messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {double textScale = 1.0, bool disableAnimations = false, double width = 360, double height = 640}) =>
    MaterialApp(
      theme: SmashTheme.light(),
      builder: (context, a) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: a!,
      ),
      home: Scaffold(body: Center(child: SizedBox(width: width, height: height, child: child))),
    );

DioException offlineError() => DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError);
DioException serverError() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: 500, data: 'x'),
    );

void main() {
  SemanticsData semanticsOf(WidgetTester tester, Finder f) => tester.getSemantics(f).getSemanticsData();

  group('SmashSkeleton', () {
    Color barColor(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(SmashSkeleton).first, matching: find.byType(DecoratedBox)).first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    testWidgets('깜빡이는 동안 색이 바뀐다', (tester) async {
      await tester.pumpWidget(app(const SmashSkeletonList()));
      final first = barColor(tester);
      await tester.pump(const Duration(milliseconds: 450));
      final second = barColor(tester);

      expect(second, isNot(first));
      await tester.pumpWidget(const SizedBox()); // 반복 애니메이션 정리
    });

    testWidgets('시스템의 동작 줄이기가 켜져 있으면 깜빡이지 않고 고정색이다', (tester) async {
      await tester.pumpWidget(app(const SmashSkeletonList(), disableAnimations: true));
      final first = barColor(tester);
      await tester.pump(const Duration(milliseconds: 450));

      expect(barColor(tester), first);
      expect(first, SmashColors.fillDisabled);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('스크린리더에는 "불러오는 중" 하나만 알리고 막대는 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const SmashSkeletonList(itemCount: 4)));

      expect(find.bySemanticsLabel('불러오는 중'), findsOneWidget);
      expect(semanticsOf(tester, find.bySemanticsLabel('불러오는 중')).flagsCollection.isLiveRegion, isTrue);
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });

    testWidgets('줄 하나의 높이는 56 이상이고, 줄 개수와 아바타 유무를 따른다', (tester) async {
      await tester.pumpWidget(app(const SmashSkeletonList(itemCount: 3)));
      expect(find.byType(ConstrainedBox).evaluate().where((e) => (e.widget as ConstrainedBox).constraints.minHeight == 56).length, 3);
      expect(find.byWidgetPredicate((w) => w is SmashSkeleton && w.circle), findsNWidgets(3));

      await tester.pumpWidget(app(const SmashSkeletonList(itemCount: 3, showAvatar: false)));
      expect(find.byWidgetPredicate((w) => w is SmashSkeleton && w.circle), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('펄스 밖에서 쓴 막대는 고정색이다 (애니메이션 없이도 쓸 수 있다)', (tester) async {
      await tester.pumpWidget(app(const SmashSkeleton(width: 100)));
      final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(SmashSkeleton), matching: find.byType(DecoratedBox)));
      expect((box.decoration as BoxDecoration).color, SmashColors.fillDisabled);
    });
  });

  group('SmashEmpty', () {
    testWidgets('제목과 설명이 보인다. 버튼은 글자와 콜백이 모두 있을 때만 보인다', (tester) async {
      await tester.pumpWidget(app(const SmashEmpty(title: '신청서가 없어요', message: '새 신청이 오면 여기에 보여요')));
      expect(find.text('신청서가 없어요'), findsOneWidget);
      expect(find.text('새 신청이 오면 여기에 보여요'), findsOneWidget);
      expect(find.byType(SmashButton), findsNothing);

      await tester.pumpWidget(app(const SmashEmpty(title: '제목', actionLabel: '새로 만들기')));
      expect(find.byType(SmashButton), findsNothing);

      var taps = 0;
      await tester.pumpWidget(app(SmashEmpty(title: '제목', actionLabel: '새로 만들기', onAction: () => taps++)));
      await tester.tap(find.text('새로 만들기'));
      expect(taps, 1);
    });

    testWidgets('scrollable이면 비어 있어도 당겨서 새로고침이 된다 (RefreshIndicator 안에서)', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(app(
        RefreshIndicator(
          onRefresh: () async => refreshed++,
          child: const SmashEmpty(title: '비어 있어요', scrollable: true),
        ),
      ));

      await tester.fling(find.text('비어 있어요'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, 1);
    });

    testWidgets('scrollable이 아니면 내용이 공간에 다 들어갈 때 당겨도 새로고침이 되지 않는다', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(app(
        RefreshIndicator(
          onRefresh: () async => refreshed++,
          child: const SmashEmpty(title: '비어 있어요'),
        ),
      ));

      await tester.fling(find.text('비어 있어요'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, 0);
    });

    testWidgets('scrollable이 아니어도 공간보다 내용이 크면(작은 칸 + 큰 글자) 넘치지 않고 끝까지 스크롤된다', (tester) async {
      await tester.pumpWidget(app(
        SmashEmpty(title: '이번 달에 참여한 활동이 아직 없어요', message: '활동에 참석하면 여기에 기록돼요.', actionLabel: '활동 보러 가기', onAction: () {}),
        textScale: 2.0,
        height: 160,
      ));

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      expect(find.text('활동 보러 가기').hitTestable(), findsOneWidget);
    });

    testWidgets('높이가 정해지지 않은 곳(Column 안)에서도 오류 없이 내용 크기로 그려진다', (tester) async {
      await tester.pumpWidget(app(const SingleChildScrollView(child: Column(children: [SmashEmpty(title: '비어 있어요')]))));

      expect(tester.takeException(), isNull);
      expect(find.text('비어 있어요'), findsOneWidget);
    });

    testWidgets('글자 2.0배 + 좁은 폭에서도 넘치지 않는다', (tester) async {
      await tester.pumpWidget(app(
        SmashEmpty(title: '이번 달에 참여한 활동이 아직 없어요', message: '활동에 참석하면 여기에 기록돼요. ' * 3, actionLabel: '활동 보러 가기', onAction: () {}, scrollable: true),
        textScale: 2.0,
        width: 280,
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('SmashErrorView', () {
    testWidgets('일반 오류: 제목, ErrorMessages 문구, 다시 시도 버튼', (tester) async {
      var retries = 0;
      await tester.pumpWidget(app(SmashErrorView(error: serverError(), onRetry: () => retries++)));

      expect(find.text('불러오지 못했어요'), findsOneWidget);
      expect(find.text(ErrorMessages.server), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(retries, 1);
    });

    testWidgets('인터넷 문제이면 제목과 아이콘이 오프라인용으로 바뀐다', (tester) async {
      await tester.pumpWidget(app(SmashErrorView(error: offlineError(), onRetry: () {})));

      expect(find.text('인터넷에 연결되지 않았어요'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
      expect(find.text(ErrorMessages.offline), findsOneWidget);
    });

    testWidgets('예외 객체의 글자는 화면에 나오지 않는다', (tester) async {
      await tester.pumpWidget(app(SmashErrorView(error: StateError('secret internal detail'), onRetry: () {})));

      expect(find.textContaining('secret'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.text(ErrorMessages.generic), findsOneWidget);
    });

    testWidgets('onRetry가 없으면 다시 시도 버튼이 없다', (tester) async {
      await tester.pumpWidget(app(SmashErrorView(error: serverError())));

      expect(find.byType(SmashButton), findsNothing);
    });

    testWidgets('나타날 때 스크린리더가 바로 읽는다 (liveRegion)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(SmashErrorView(error: serverError(), onRetry: () {})));

      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('불러오지 못했어요')));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('scrollable이면 오류 화면에서도 당겨서 새로고침이 된다', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(app(
        RefreshIndicator(
          onRefresh: () async => refreshed++,
          child: SmashErrorView(error: serverError(), scrollable: true),
        ),
      ));

      await tester.fling(find.text('불러오지 못했어요'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, 1);
    });

    testWidgets('글자 2.0배에서도 넘치지 않는다', (tester) async {
      await tester.pumpWidget(app(SmashErrorView(error: offlineError(), onRetry: () {}, scrollable: true), textScale: 2.0, width: 280));

      expect(tester.takeException(), isNull);
    });
  });

  group('SmashErrorBanner', () {
    testWidgets('인터넷 문제이면 주의(오프라인) 안내, 아니면 오류 안내', (tester) async {
      await tester.pumpWidget(app(SmashErrorBanner(error: offlineError(), onRetry: () {})));
      expect(find.text('인터넷에 연결되지 않았어요'), findsOneWidget);
      expect(find.byIcon(SmashInlineNotice.iconFor(SmashNoticeTone.warning)), findsOneWidget);

      await tester.pumpWidget(app(SmashErrorBanner(error: serverError(), onRetry: () {})));
      expect(find.text(ErrorMessages.server), findsOneWidget);
      expect(find.byIcon(SmashInlineNotice.iconFor(SmashNoticeTone.danger)), findsOneWidget);
    });

    testWidgets('다시 시도가 불린다', (tester) async {
      var retries = 0;
      await tester.pumpWidget(app(SmashErrorBanner(error: serverError(), onRetry: () => retries++)));

      await tester.tap(find.text('다시 시도'));

      expect(retries, 1);
    });
  });

  group('SmashAsyncView', () {
    Widget view(AsyncValue<int> value, {VoidCallback? onRetry, bool Function(int)? isEmpty, Widget? empty, Widget? loading}) => app(
          SmashAsyncView<int>(
            value: value,
            onRetry: onRetry,
            isEmpty: isEmpty,
            empty: empty,
            loading: loading,
            data: (context, data) => Center(child: Text('값 $data')),
          ),
        );

    testWidgets('처음 불러오는 중이면 스켈레톤(또는 지정한 loading)을 보여준다', (tester) async {
      await tester.pumpWidget(view(const AsyncLoading<int>()));
      expect(find.byType(SmashSkeletonList), findsOneWidget);

      await tester.pumpWidget(view(const AsyncLoading<int>(), loading: const Text('직접 만든 로딩')));
      expect(find.text('직접 만든 로딩'), findsOneWidget);
      expect(find.byType(SmashSkeletonList), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('값이 있으면 내용을 그린다', (tester) async {
      await tester.pumpWidget(view(const AsyncData(7)));

      expect(find.text('값 7'), findsOneWidget);
      expect(find.byType(SmashErrorView), findsNothing);
    });

    testWidgets('isEmpty가 true이면 empty를, empty가 없으면 기본 빈 화면을 보여준다', (tester) async {
      await tester.pumpWidget(view(const AsyncData(0), isEmpty: (v) => v == 0, empty: const SmashEmpty(title: '직접 만든 빈 화면')));
      expect(find.text('직접 만든 빈 화면'), findsOneWidget);
      expect(find.text('값 0'), findsNothing);

      await tester.pumpWidget(view(const AsyncData(0), isEmpty: (v) => v == 0));
      expect(find.byType(SmashEmpty), findsOneWidget);

      await tester.pumpWidget(view(const AsyncData(1), isEmpty: (v) => v == 0));
      expect(find.text('값 1'), findsOneWidget);
    });

    testWidgets('이전 내용 없이 실패하면 오류 화면이고, 다시 시도가 불린다', (tester) async {
      var retries = 0;
      await tester.pumpWidget(view(AsyncError<int>(serverError(), StackTrace.empty), onRetry: () => retries++));

      expect(find.byType(SmashErrorView), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(retries, 1);
    });

    testWidgets('오류 뒤 다시 시도해서 불러오는 중이면 오류 화면이 아니라 로딩을 보여준다', (tester) async {
      final retrying = const AsyncLoading<int>().copyWithPrevious(AsyncError<int>(serverError(), StackTrace.empty));
      await tester.pumpWidget(view(retrying));

      expect(find.byType(SmashSkeletonList), findsOneWidget);
      expect(find.byType(SmashErrorView), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('내용이 있는 채 새로고침 중이면 내용을 그대로 두고 로딩 화면으로 바꾸지 않는다', (tester) async {
      final refreshing = const AsyncLoading<int>().copyWithPrevious(const AsyncData(5));
      await tester.pumpWidget(view(refreshing));

      expect(find.text('값 5'), findsOneWidget);
      expect(find.byType(SmashSkeletonList), findsNothing);
    });

    testWidgets('내용이 있는데 새로고침에 실패하면 내용은 두고 위에 안내만 붙인다', (tester) async {
      var retries = 0;
      final failed = AsyncError<int>(offlineError(), StackTrace.empty).copyWithPrevious(const AsyncData(5));
      await tester.pumpWidget(view(failed, onRetry: () => retries++));

      expect(find.text('값 5'), findsOneWidget);
      expect(find.byType(SmashErrorView), findsNothing);
      expect(find.byType(SmashErrorBanner), findsOneWidget);
      expect(find.text('인터넷에 연결되지 않았어요'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(SmashErrorBanner)).dy, lessThan(tester.getTopLeft(find.text('값 5')).dy));
      await tester.tap(find.text('다시 시도'));
      expect(retries, 1);
    });

    testWidgets('새로고침에 실패한 뒤 다시 시도하는 중이면 이전 오류 안내는 사라지고 내용은 그대로다', (tester) async {
      final failed = AsyncError<int>(offlineError(), StackTrace.empty).copyWithPrevious(const AsyncData(5));
      final retrying = const AsyncLoading<int>().copyWithPrevious(failed);
      expect(retrying.hasError && retrying.isLoading && retrying.hasValue, isTrue, reason: '이 테스트가 겨냥하는 상태가 맞는지 확인');

      await tester.pumpWidget(view(retrying));

      expect(find.text('값 5'), findsOneWidget);
      expect(find.byType(SmashErrorBanner), findsNothing);
      expect(find.byType(SmashSkeletonList), findsNothing);
    });

    testWidgets('새로고침 실패 + 이전 내용이 비어 있으면 빈 화면과 안내가 함께 보인다', (tester) async {
      final failed = AsyncError<int>(serverError(), StackTrace.empty).copyWithPrevious(const AsyncData(0));
      await tester.pumpWidget(view(failed, isEmpty: (v) => v == 0));

      expect(find.byType(SmashEmpty), findsOneWidget);
      expect(find.byType(SmashErrorBanner), findsOneWidget);
    });

    testWidgets('실제 Riverpod provider 상태 전환: 로딩 → 데이터', (tester) async {
      final provider = FutureProvider<int>((ref) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 9;
      });
      await tester.pumpWidget(ProviderScope(
        child: Consumer(builder: (context, ref, _) => view(ref.watch(provider))),
      ));
      expect(find.byType(SmashSkeletonList), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      expect(find.text('값 9'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('SocketException으로 실패해도 오프라인 안내가 나온다 (Dio unknown 타입)', (tester) async {
      final socket = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
        error: const SocketException('x'),
      );
      await tester.pumpWidget(view(AsyncError<int>(socket, StackTrace.empty), onRetry: () {}));

      expect(find.text('인터넷에 연결되지 않았어요'), findsWidgets);
    });
  });
}
