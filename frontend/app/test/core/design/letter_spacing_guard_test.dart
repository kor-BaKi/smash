import 'package:app/core/design/components/components.dart';
import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/design/typography.dart';
import 'package:app/dev/catalog/catalog_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 글자 자간 지킴이.
///
/// 토큰이 자간을 명시하지 않으면 Flutter가 테마의 기본 글자 스타일(Material 3: bodyMedium 0.25, bodyLarge 0.5 등)의
/// 자간을 섞어서, 같은 토큰이 자리마다 다른 자간으로 그려지고 `TextPainter`로 잰 폭과도 어긋났다.
/// 그 일이 다시 생기지 않게 (1) 토큰, (2) 테마의 글자 역할, (3) 카탈로그의 모든 글자, (4) 오버레이 안의 글자를 검사한다.
void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR', null));

  /// 허용되는 자간: 토큰이 정의한 값뿐이다 (본문, 강조 본문, 캡션 0 + 제목 토큰들)
  final allowed = SmashText.all.map((s) => s.letterSpacing).toSet();

  group('① 토큰은 모두 자간을 명시한다', () {
    test('모든 토큰의 letterSpacing이 null이 아니다', () {
      for (final style in SmashText.all) {
        expect(
          style.letterSpacing,
          isNotNull,
          reason: '${style.fontSize}sp w${style.fontWeight?.value}',
        );
      }
      expect(
        SmashText.all.length,
        6,
        reason: '토큰을 더하면 이 목록(SmashText.all)에도 넣는다',
      );
    });

    test(
      '본문, 강조 본문, 캡션은 0이고 제목 토큰은 그대로다 (heading -0.2, title -0.3, display -0.4)',
      () {
        expect(SmashText.body.letterSpacing, 0);
        expect(SmashText.bodyStrong.letterSpacing, 0);
        expect(SmashText.caption.letterSpacing, 0);
        expect(SmashText.heading.letterSpacing, -0.2);
        expect(SmashText.title.letterSpacing, -0.3);
        expect(SmashText.display.letterSpacing, -0.4);
      },
    );

    test('토큰에서 파생한 스타일은 자간을 물려받는다 (copyWith(fontSize), tabular)', () {
      expect(SmashText.body.copyWith(fontSize: 12).letterSpacing, 0);
      expect(SmashText.tabular(SmashText.caption).letterSpacing, 0);
      expect(SmashText.heading.copyWith(fontSize: 20).letterSpacing, -0.2);
    });
  });

  group('② 테마의 글자 역할이 토큰과 같은 자간이다', () {
    // 앱이 실제로 쓰는 값은 `Theme.of(context)`로 읽을 때 Material 기본값이 합쳐진 값이다.
    // `SmashTheme.light().textTheme`을 바로 읽으면 합쳐지기 전 값이라 누수를 못 잡는다
    testWidgets(
      'Theme.of(context)가 돌려주는 모든 글자 역할의 자간 = 해당 토큰의 자간 (Material 기본값이 섞이지 않는다)',
      (tester) async {
        late TextTheme t;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                t = Theme.of(context).textTheme;
                return const SizedBox();
              },
            ),
          ),
        );
        final roles = <String, (TextStyle?, TextStyle)>{
          'displaySmall': (t.displaySmall, SmashText.display),
          'headlineSmall': (t.headlineSmall, SmashText.title),
          'titleLarge': (t.titleLarge, SmashText.title),
          'titleMedium': (t.titleMedium, SmashText.heading),
          'titleSmall': (t.titleSmall, SmashText.bodyStrong),
          'bodyLarge': (t.bodyLarge, SmashText.body),
          'bodyMedium': (t.bodyMedium, SmashText.body),
          'bodySmall': (t.bodySmall, SmashText.caption),
          'labelLarge': (t.labelLarge, SmashText.bodyStrong),
          'labelMedium': (t.labelMedium, SmashText.caption),
          'labelSmall': (t.labelSmall, SmashText.caption),
        };
        for (final entry in roles.entries) {
          final (role, token) = entry.value;
          expect(role, isNotNull, reason: entry.key);
          expect(
            role!.letterSpacing,
            token.letterSpacing,
            reason: '${entry.key}: Material 기본 자간이 섞여 있다',
          );
        }
      },
    );

    testWidgets(
      '테마가 정의하지 않은 역할(displayLarge/Medium, headlineLarge/Medium)은 Material 기본값을 쓴다 (현재 쓰는 곳이 없고, 쓰는 위젯이 생기면 ③이 잡는다)',
      (tester) async {
        late TextTheme t;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                t = Theme.of(context).textTheme;
                return const SizedBox();
              },
            ),
          ),
        );
        // 이 역할을 쓰는 위젯이 생기면 토큰으로 정의하거나(SmashTheme) 그 위젯이 자간을 명시해야 한다
        for (final style in [
          t.displayLarge,
          t.displayMedium,
          t.headlineLarge,
          t.headlineMedium,
        ]) {
          expect(style, isNotNull);
        }
      },
    );
  });

  /// 화면에 그려진 모든 글자(아이콘 제외)의 자간을 모아 허용 집합 밖인 것을 돌려준다
  List<String> offenders(WidgetTester tester, String where) {
    final bad = <String>[];
    var seen = 0;
    for (final element in find.byType(RichText).evaluate()) {
      final render = element.renderObject;
      if (render is! RenderParagraph) continue;
      final text = render.text.toPlainText();
      if (text.trim().isEmpty) continue;
      // 아이콘은 사설 영역 글자(E000-F8FF)로 그려진다
      if (text.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
      seen++;
      final spacing = render.text.style?.letterSpacing;
      if (spacing == null || !allowed.contains(spacing)) {
        bad.add('$where: "${text.replaceAll('\n', ' ')}" 자간=$spacing');
      }
    }
    _seen += seen;
    return bad;
  }

  group('③ 카탈로그의 모든 상태의 모든 글자가 허용된 자간이다', () {
    testWidgets('등록된 모든 컴포넌트, 모든 상태 (글자 1.0배: 자간은 글자 배율과 무관한 고정값)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _seen = 0;
      final bad = <String>[];
      var states = 0;
      for (final entry in catalogEntries) {
        for (final state in entry.states) {
          states++;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: SingleChildScrollView(
                  child: Builder(builder: state.builder),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final exception = tester.takeException();
          expect(exception, isNull, reason: '${entry.name} / ${state.label}');
          bad.addAll(offenders(tester, '${entry.name} / ${state.label}'));
        }
      }

      expect(states, greaterThan(100), reason: '카탈로그 상태를 모두 돌았다');
      expect(_seen, greaterThan(1000), reason: '검사가 헛돌지 않도록 충분한 글자를 봤다');
      expect(
        bad,
        isEmpty,
        reason: '허용(${allowed.toList()}) 밖의 자간:\n${bad.take(20).join('\n')}',
      );
    });
  });

  group('④ 오버레이(시트, 대화상자, 팝업, 스낵바) 안의 글자도 허용된 자간이다', () {
    Future<void> scan(
      WidgetTester tester,
      String name,
      void Function(BuildContext context) open, {
      Future<void> Function()? after,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      late BuildContext ctx;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      open(ctx);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      if (after != null) await after();
      final before = _seen;
      final bad = offenders(tester, name);
      expect(
        _seen - before,
        greaterThan(0),
        reason: '$name: 글자를 하나도 못 봤다 (오버레이가 안 열렸다)',
      );
      expect(bad, isEmpty, reason: bad.join('\n'));
    }

    testWidgets('showSmashSheet (제목줄과 본문)', (tester) async {
      await scan(
        tester,
        'SmashSheet',
        (c) => showSmashSheet<void>(
          context: c,
          title: '제목',
          builder: (_) => const SmashLabel('시트 안의 본문 글자예요'),
        ),
      );
    });

    testWidgets('showSmashConfirm / showSmashAlert (대화상자 제목, 설명, 버튼)', (
      tester,
    ) async {
      await scan(
        tester,
        '확인 대화상자',
        (c) => showSmashConfirm(
          context: c,
          title: '삭제할까요?',
          message: '되돌릴 수 없어요',
          confirmLabel: '삭제',
          destructive: true,
        ),
      );
      await scan(
        tester,
        '알림 대화상자',
        (c) => showSmashAlert(context: c, title: '알림', message: '저장했어요'),
      );
    });

    testWidgets('showSmashActionSheet (행, 아이콘, 취소)', (tester) async {
      await scan(
        tester,
        '행동 시트',
        (c) => showSmashActionSheet<String>(
          context: c,
          title: '조 관리',
          message: '조를 관리해요',
          actions: const [
            SmashAction(value: 'a', label: '이름 바꾸기', icon: Icons.edit_outlined),
            SmashAction(
              value: 'b',
              label: '조 삭제',
              icon: Icons.delete_outline,
              destructive: true,
            ),
          ],
        ),
      );
    });

    testWidgets('SmashSelectField의 선택지 시트', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SmashSelectField<String>(
              label: '조',
              value: 'a',
              options: const [
                SmashOption(value: 'a', label: '1조', subtitle: '설명'),
                SmashOption(value: 'b', label: '2조'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SmashPressable).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final before = _seen;
      final bad = offenders(tester, '선택 시트');
      expect(_seen - before, greaterThan(0));
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    testWidgets('showSmashDatePicker (달력 시트)', (tester) async {
      await scan(
        tester,
        '날짜 시트',
        (c) => showSmashDatePicker(
          context: c,
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2027, 12, 31),
          initialDate: DateTime(2026, 11, 12),
          today: DateTime(2026, 11, 11),
        ),
      );
    });

    testWidgets('showSmashDateTimePicker와 시/분 팝업', (tester) async {
      await scan(
        tester,
        '날짜+시간 시트',
        (c) => showSmashDateTimePicker(
          context: c,
          today: DateTime(2026, 11, 11),
          constraints: SmashDateTimeConstraints(
            firstDate: DateTime(2026, 11, 11),
            lastDate: DateTime(2027, 12, 31),
            isSelectable: (_) => true,
            initialValue: DateTime(2026, 11, 12, 15, 30),
          ),
        ),
        after: () async {
          await tester.tap(
            find.byWidgetPredicate(
              (w) =>
                  w is SmashPressable &&
                  (w.semanticLabel ?? '').startsWith('시 선택'),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        },
      );
    });

    testWidgets('showSmashSnackBar', (tester) async {
      await scan(
        tester,
        '스낵바',
        (c) => showSmashSnackBar(
          c,
          '저장했어요',
          tone: SmashSnackTone.success,
          actionLabel: '되돌리기',
          onAction: () {},
        ),
      );
    });
  });
}

int _seen = 0;

Widget _app(Widget home) => MaterialApp(
  theme: SmashTheme.light(),
  locale: const Locale('ko', 'KR'),
  supportedLocales: const [Locale('ko', 'KR')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
