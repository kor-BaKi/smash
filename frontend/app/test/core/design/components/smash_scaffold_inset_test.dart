import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `SmashScaffold`가 본문에 넘기는 `MediaQuery`(안전 영역, 키보드)와 본문 위치.
///
/// 하단 막대가 있으면 막대가 아래 안전 영역(홈 인디케이터)을 맡으므로 본문 안쪽의 `padding.bottom`은 0이어야 한다
/// (본문 안의 `SafeArea`나 기본 여백의 `ListView`가 같은 영역을 또 비우지 않는다).
/// 막대가 없을 때의 동작, 위쪽 안전 영역, 키보드 처리, 본문과 막대의 위치는 바뀌지 않는다.
const _size = Size(402, 874);
const _top = 62.0;
const _bottom = 34.0;

class _Seen {
  EdgeInsets? padding;
  EdgeInsets? viewPadding;
  EdgeInsets? viewInsets;
}

/// 본문 자리에서 자기가 받은 MediaQuery를 기록한다
Widget _probe(_Seen seen) => Builder(
  builder: (context) {
    final media = MediaQuery.of(context);
    seen
      ..padding = media.padding
      ..viewPadding = media.viewPadding
      ..viewInsets = media.viewInsets;
    return const SizedBox.expand(key: ValueKey('body'));
  },
);

/// 실제 기기처럼: 키보드가 올라오면 아래 안전 영역(padding)은 줄어들고 viewPadding은 그대로다
Widget _app(Widget home, {double keyboard = 0}) => MaterialApp(
  theme: SmashTheme.light(),
  builder: (context, app) {
    final bottomPadding = (_bottom - keyboard).clamp(0.0, _bottom);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.only(top: _top, bottom: bottomPadding),
        viewPadding: const EdgeInsets.only(top: _top, bottom: _bottom),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: app!,
    );
  },
  home: home,
);

const _bar = SizedBox(key: ValueKey('bar'), height: 50);
const _appBar = SmashAppBar(title: '제목');

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double keyboard = 0,
}) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home, keyboard: keyboard));
  await tester.pumpAndSettle();
}

void main() {
  group('본문이 받는 MediaQuery', () {
    testWidgets(
      '하단 막대가 있으면(앱바 없음): 아래 안전 영역(padding.bottom, viewPadding.bottom)이 0이다',
      (tester) async {
        final seen = _Seen();
        await _pump(tester, SmashScaffold(body: _probe(seen), bottom: _bar));
        expect(seen.padding, EdgeInsets.zero);
        expect(seen.viewPadding!.bottom, 0);
      },
    );

    testWidgets('하단 막대 + 앱바: 아래는 0이고 위쪽은 그대로다 (바뀌지 않는다)', (tester) async {
      final seen = _Seen();
      await _pump(
        tester,
        SmashScaffold(appBar: _appBar, body: _probe(seen), bottom: _bar),
      );
      expect(seen.padding!.bottom, 0);
      expect(seen.padding!.top, _top, reason: '위쪽 안전 영역 처리는 이번에 바꾸지 않았다');
    });

    testWidgets('하단 막대가 없으면(앱바 없음): 기존과 같다 (본문이 안전 영역을 피하고 안쪽은 0)', (
      tester,
    ) async {
      final seen = _Seen();
      await _pump(tester, SmashScaffold(body: _probe(seen)));
      expect(seen.padding, EdgeInsets.zero);
    });

    testWidgets('하단 막대가 없으면(앱바 있음): 기존과 같다 (위는 그대로, 아래는 본문이 피해서 0)', (
      tester,
    ) async {
      final seen = _Seen();
      await _pump(tester, SmashScaffold(appBar: _appBar, body: _probe(seen)));
      expect(seen.padding!.top, _top);
      expect(seen.padding!.bottom, 0);
    });

    testWidgets('키보드가 올라와도 본문은 키보드 높이(viewInsets)를 받지 않는다, 막대가 있든 없든 기존과 같다', (
      tester,
    ) async {
      final withBar = _Seen();
      await _pump(
        tester,
        SmashScaffold(body: _probe(withBar), bottom: _bar),
        keyboard: 300,
      );
      expect(withBar.viewInsets!.bottom, 0);
      expect(withBar.padding!.bottom, 0);

      final withoutBar = _Seen();
      await _pump(
        tester,
        SmashScaffold(body: _probe(withoutBar)),
        keyboard: 300,
      );
      expect(withoutBar.padding!.bottom, 0);
      expect(withoutBar.padding!.top, 0, reason: '앱바가 없으면 본문이 위쪽 안전 영역을 피한다');
    });
  });

  group('본문과 막대의 위치는 바뀌지 않는다', () {
    testWidgets('막대 있음: 본문은 위 안전 영역 아래에서 막대 바로 위까지', (tester) async {
      await _pump(tester, SmashScaffold(body: _probe(_Seen()), bottom: _bar));
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      expect(body.top, _top);
      expect(body.bottom, bar.top);
      expect(bar.bottom, _size.height, reason: '막대는 화면 맨 아래');
    });

    testWidgets('막대 없음: 본문은 위아래 안전 영역을 피한다', (tester) async {
      await _pump(tester, SmashScaffold(body: _probe(_Seen())));
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      expect(body.top, _top);
      expect(body.bottom, _size.height - _bottom);
    });

    testWidgets('키보드가 올라오면 막대는 키보드 위에 붙고 본문은 막대 위까지다', (tester) async {
      await _pump(
        tester,
        SmashScaffold(body: _probe(_Seen()), bottom: _bar),
        keyboard: 300,
      );
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      expect(bar.bottom, _size.height - 300);
      expect(body.bottom, bar.top);
    });
  });

  group('본문 안의 SafeArea와 ListView', () {
    testWidgets('막대 있음: 본문 안의 SafeArea는 아래를 또 비우지 않는다', (tester) async {
      await _pump(
        tester,
        SmashScaffold(
          body: const SafeArea(child: SizedBox.expand(key: ValueKey('inner'))),
          bottom: _bar,
        ),
      );
      final body = tester.getRect(find.byKey(const ValueKey('inner')));
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      expect(body.bottom, bar.top, reason: '안쪽 SafeArea가 아래 34를 또 비우지 않는다');
    });

    testWidgets('막대 있음: 기본 여백의 ListView도 끝까지 스크롤하면 마지막 항목이 막대 바로 위에 닿는다', (
      tester,
    ) async {
      await _pump(
        tester,
        SmashScaffold(
          body: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(key: ValueKey('item$i'), height: 80),
            ],
          ),
          bottom: _bar,
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.byKey(const ValueKey('item29')));
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      expect(last.bottom, bar.top, reason: '끝에 34 여백이 더 남지 않는다');
    });

    testWidgets('막대 없음: 본문이 안전 영역을 피하므로 ListView 끝도 안전 영역 위에서 끝난다 (기존과 같다)', (
      tester,
    ) async {
      await _pump(
        tester,
        SmashScaffold(
          body: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(key: ValueKey('item$i'), height: 80),
            ],
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.byKey(const ValueKey('item29')));
      expect(last.bottom, _size.height - _bottom);
    });
  });

  group('SmashTabShell', () {
    const tabs = [
      SmashNavDestination(label: '하나', icon: Icons.home_outlined),
      SmashNavDestination(label: '둘', icon: Icons.circle_outlined),
    ];

    testWidgets('탭 막대가 있으면 본문 안쪽의 아래 안전 영역은 0이고, 막대 자신은 안전 영역을 여전히 비운다', (
      tester,
    ) async {
      final seen = _Seen();
      await _pump(
        tester,
        SmashTabShell(
          destinations: tabs,
          selectedIndex: 0,
          onSelected: (_) {},
          body: _probe(seen),
        ),
      );
      expect(seen.padding!.bottom, 0);
      final nav = tester.getRect(find.byType(SmashBottomNav));
      expect(nav.bottom, _size.height);
      expect(
        nav.height,
        greaterThan(_bottom + 48),
        reason: '막대 안쪽에 홈 인디케이터 여백(34)이 그대로 있다',
      );
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      expect(body.bottom, nav.top);
    });

    testWidgets('키보드가 올라와 탭 막대가 숨으면 기존과 같다 (본문 안쪽 padding은 0)', (tester) async {
      final seen = _Seen();
      await _pump(
        tester,
        SmashTabShell(
          destinations: tabs,
          selectedIndex: 0,
          onSelected: (_) {},
          body: _probe(seen),
        ),
        keyboard: 300,
      );
      expect(find.byType(SmashBottomNav), findsNothing);
      expect(seen.padding!.bottom, 0);
      // 막대가 없으면 키보드 높이는 기존처럼 본문에 그대로 전달된다 (바뀌지 않았다)
      expect(seen.viewInsets!.bottom, 300);
    });
  });
}
