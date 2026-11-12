import 'package:app/core/design/smash_theme.dart';
import 'package:app/core/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';

void main() {
  final theme = SmashTheme.light();

  group('테마 값', () {
    test('라이트 테마이고 브랜드 색이 주 색이다', () {
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, SmashColors.brand);
      expect(theme.colorScheme.onPrimary, SmashColors.onBrand);
      expect(theme.colorScheme.error, SmashColors.danger);
      expect(theme.colorScheme.surface, SmashColors.surface);
      expect(theme.scaffoldBackgroundColor, SmashColors.background);
    });

    test('글꼴은 Pretendard, 굵기는 400과 600만 쓴다', () {
      expect(theme.textTheme.bodyLarge!.fontFamily, SmashText.family);
      final styles = [
        theme.textTheme.displaySmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
      ];
      for (final style in styles) {
        expect(style!.fontWeight, anyOf(FontWeight.w400, FontWeight.w600));
        expect(style.fontSize, greaterThanOrEqualTo(13));
      }
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
    });

    test('밝은 배경에서 상태 표시줄 아이콘은 어둡게', () {
      final overlay = theme.appBarTheme.systemOverlayStyle!;

      expect(overlay.statusBarIconBrightness, Brightness.dark);
      expect(overlay.statusBarBrightness, Brightness.light);
    });

    test('입력창 테두리는 조작 요소 대비 3:1을 만족하는 border 색이다', () {
      final enabled = theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;

      expect(enabled.borderSide.color, SmashColors.border);
      expect(contrastRatio(enabled.borderSide.color, SmashColors.surface),
          greaterThanOrEqualTo(3.0));
    });

    test('입력창 포커스는 브랜드 2px, 오류는 위험색', () {
      final focused = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      final error = theme.inputDecorationTheme.errorBorder as OutlineInputBorder;

      expect(focused.borderSide.color, SmashColors.brand);
      expect(focused.borderSide.width, 2);
      expect(error.borderSide.color, SmashColors.danger);
    });

    test('시트는 위쪽만 24로 둥글고, 다이얼로그는 16으로 둥글다', () {
      final sheet = theme.bottomSheetTheme.shape as RoundedRectangleBorder;
      final dialog = theme.dialogTheme.shape as RoundedRectangleBorder;

      expect(sheet.borderRadius, SmashRadius.sheetTop);
      expect(dialog.borderRadius, BorderRadius.circular(SmashRadius.lg));
    });

    test('스낵바는 어두운 배경에 밝은 글자(대비 4.5:1 이상)다', () {
      final snack = theme.snackBarTheme;

      expect(contrastRatio(snack.contentTextStyle!.color!, snack.backgroundColor!),
          greaterThanOrEqualTo(4.5));
      expect(contrastRatio(snack.actionTextColor!, snack.backgroundColor!),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('글자 크기 확대 (1.0, 1.3, 2.0배)', () {
    Widget harness(double scale) {
      return MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(SmashSpacing.md),
            child: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('참여할게요')),
                OutlinedButton(onPressed: () {}, child: const Text('불참해요')),
                TextButton(onPressed: () {}, child: const Text('취소')),
                const TextField(
                  decoration: InputDecoration(labelText: '학번', helperText: '숫자만 입력해 주세요'),
                ),
                Row(children: [
                  Switch(value: true, onChanged: (_) {}),
                  Checkbox(value: true, onChanged: (_) {}),
                  RadioGroup<int>(
                    groupValue: 1,
                    onChanged: (_) {},
                    child: const Radio<int>(value: 1),
                  ),
                ]),
                const ListTile(title: Text('수 1-3시'), subtitle: Text('참석 12명')),
                const Chip(label: Text('이번 주')),
              ],
            ),
          ),
        ),
      );
    }

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('배율 $scale: 오류 없이 그려지고 버튼과 체크, 스위치의 터치 영역이 48dp 이상이다',
          (tester) async {
        await tester.pumpWidget(harness(scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final type in [FilledButton, OutlinedButton, TextButton]) {
          final size = tester.getSize(find.byType(type));
          expect(size.height, greaterThanOrEqualTo(48), reason: '$type @$scale');
        }
        expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(52));
        for (final type in [Switch, Checkbox, Radio<int>]) {
          final size = tester.getSize(find.byType(type));
          expect(size.height, greaterThanOrEqualTo(48), reason: '$type @$scale');
        }
        expect(tester.getSize(find.byType(ListTile)).height, greaterThanOrEqualTo(56));
      });
    }

    testWidgets('글자가 커지면 버튼 높이는 줄지 않고 늘어난다', (tester) async {
      await tester.pumpWidget(harness(1.0));
      final normal = tester.getSize(find.byType(FilledButton)).height;
      await tester.pumpWidget(harness(2.0));
      await tester.pumpAndSettle();
      final large = tester.getSize(find.byType(FilledButton)).height;

      expect(large, greaterThanOrEqualTo(normal));
    });
  });

  group('화면 단위 적용 (기존 어두운 앱 안에서)', () {
    Future<void> pumpScoped(WidgetTester tester, Widget Function(BuildContext) body) {
      return tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(), // 전환 전의 어두운 앱을 흉내낸다
        home: Theme(
          data: theme,
          child: Builder(builder: (context) => Scaffold(body: body(context))),
        ),
      ));
    }

    testWidgets('감싼 화면 안에서는 SMASH 라이트 테마가 적용된다', (tester) async {
      late ThemeData inner;
      await pumpScoped(tester, (context) {
        inner = Theme.of(context);
        return const SizedBox();
      });

      expect(inner.brightness, Brightness.light);
      expect(inner.colorScheme.primary, SmashColors.brand);
    });

    testWidgets('그 화면에서 연 다이얼로그도 라이트 테마를 따른다', (tester) async {
      late BuildContext screen;
      await pumpScoped(tester, (context) {
        screen = context;
        return const SizedBox();
      });

      Brightness? inDialog;
      Color? primaryInDialog;
      showDialog<void>(
        context: screen,
        builder: (dialogContext) {
          inDialog = Theme.of(dialogContext).brightness;
          primaryInDialog = Theme.of(dialogContext).colorScheme.primary;
          return const AlertDialog(content: Text('확인'));
        },
      );
      await tester.pumpAndSettle();

      expect(inDialog, Brightness.light);
      expect(primaryInDialog, SmashColors.brand);
    });

    testWidgets('그 화면에서 연 바텀시트도 라이트 테마를 따른다', (tester) async {
      late BuildContext screen;
      await pumpScoped(tester, (context) {
        screen = context;
        return const SizedBox();
      });

      Brightness? inSheet;
      showModalBottomSheet<void>(
        context: screen,
        builder: (sheetContext) {
          inSheet = Theme.of(sheetContext).brightness;
          return const SizedBox(height: 100);
        },
      );
      await tester.pumpAndSettle();

      expect(inSheet, Brightness.light);
    });
  });

  test('SystemUiOverlayStyle 은 투명 상태 표시줄을 쓴다', () {
    expect(theme.appBarTheme.systemOverlayStyle!.statusBarColor, Colors.transparent);
    expect(SystemUiOverlayStyle.dark.statusBarIconBrightness, Brightness.dark);
  });
}
