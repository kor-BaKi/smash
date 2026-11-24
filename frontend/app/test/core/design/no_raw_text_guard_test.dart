import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 컴포넌트의 글자는 모두 `SmashLabel`로 그린다 (한글이 낱말 중간에서 줄바꿈되지 않고, 스크린리더는 원문을 읽는다).
///
/// 이 지킴이는 `lib/core/design/components`의 소스에서 `Text(`, `Text.rich(`, `Text.new`, `RichText(`을 찾는다
/// (주석과 문자열 안은 제외, `prefix.Text(` 같은 접두어 호출도 포함).
/// 허용 목록은 [_allowed]뿐이며, 새 예외는 이유와 함께 여기에 추가한다.
void main() {
  /// 파일 → 허용하는 호출 수와 이유
  const allowed = <String, (int, String)>{
    'smash_label.dart': (
      1,
      'SmashLabel 자신이 WORD JOINER를 넣은 일반 Text에게 그리기를 맡긴다 (build 안의 Text(...).build)',
    ),
  };

  group('스캐너 점검 (가짜 소스)', () {
    int count(String source) => rawTextCalls(source).length;

    test('Text(, const Text(, Text.rich(, Text.new, RichText(을 찾는다', () {
      expect(count("final a = Text('가');"), 1);
      expect(count("final a = const Text('가');"), 1);
      expect(count("final a = Text.rich(TextSpan(text: '가'));"), 1);
      expect(count('final a = Text.new;'), 1);
      expect(count("final a = RichText(text: TextSpan(text: '가'));"), 1);
    });

    test('줄바꿈이나 공백이 끼어도 찾는다', () {
      expect(count('final a = Text\n  (\n  data);'), 1);
      expect(count('final a = Text.rich\n(x);'), 1);
    });

    test('접두어 import로 부르는 호출도 찾는다 (m.Text(, material.RichText()', () {
      expect(count("final a = m.Text('가');"), 1);
      expect(count('final a = material.RichText(text: x);'), 1);
    });

    test('여러 개면 모두 센다', () {
      expect(
        count("Column(children: [Text('a'), Text('b'), RichText(text: x)])"),
        3,
      );
    });

    test(
      'SmashLabel, TextField, SelectableText, TextSpan, DefaultTextStyle, 변수 이름은 찾지 않는다',
      () {
        expect(count("final a = SmashLabel('가');"), 0);
        expect(count('final a = TextField();'), 0);
        expect(count('final a = SelectableText(x);'), 0);
        expect(count("final a = TextSpan(text: '가');"), 0);
        expect(count('final a = DefaultTextStyle(style: s, child: c);'), 0);
        expect(count('final MyText(x) = y;'), 0);
        expect(count('final a = hintText(x);'), 0);
      },
    );

    test('옛 테마 사용을 찾는다 (AppColors, core/theme import)', () {
      expect(oldThemeUses("final c = AppColors.bg;"), isNotEmpty);
      expect(oldThemeUses("color: AppColors.white,"), isNotEmpty);
      expect(oldThemeUses("import '../../../core/theme/app_theme.dart';"), isNotEmpty);
      expect(oldThemeUses("import 'package:app/core/theme/app_colors.dart';"), isNotEmpty);
      expect(oldThemeUses('final c = SmashColors.brand;'), isEmpty);
      expect(oldThemeUses('final MyAppColors = 1;'), isEmpty, reason: '다른 이름의 일부는 찾지 않는다');
      expect(oldThemeUses('// AppColors는 쓰지 않는다'), isEmpty, reason: '주석은 제외');
      expect(oldThemeUses("final s = 'AppColors.bg';"), isEmpty, reason: '문자열 안은 제외');
    });

    test('주석, 문서 주석, 블록 주석, 문자열 안은 제외한다', () {
      expect(count("// Text('가')"), 0);
      expect(count("/// `Text(...)`를 쓰지 않는다"), 0);
      expect(count("/* Text('가') */ final a = 1;"), 0);
      expect(count("final a = 'Text(가)';"), 0);
      expect(count('final a = "Text(가)";'), 0);
      expect(count("final a = 'it\\'s Text(';"), 0);
      expect(
        count("final a = 'http://x'; final b = Text('가');"),
        1,
        reason: "문자열 안의 //는 주석이 아니다",
      );
      expect(
        count("final a = '\${Text('가')}';"),
        0,
        reason: '문자열 보간 안은 문자열로 본다 (보수적이지 않지만 단순한 규칙)',
      );
    });
  });

  group('컴포넌트 소스 전수 조사', () {
    final dir = Directory('lib/core/design/components');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('조사 대상 파일을 충분히 찾았다 (경로가 틀려 헛돌지 않는다)', () {
      expect(files.length, greaterThan(35));
      expect(files.any((f) => f.path.endsWith('smash_label.dart')), isTrue);
    });

    test('Text(, Text.rich(, Text.new, RichText(은 허용 목록 밖에서 쓰지 않는다', () {
      final found = <String, int>{};
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final n = rawTextCalls(file.readAsStringSync()).length;
        if (n > 0) found[name] = n;
      }
      final unexpected = <String>[
        for (final e in found.entries)
          if (e.value != (allowed[e.key]?.$1 ?? 0))
            '${e.key}: ${e.value}곳 (허용 ${allowed[e.key]?.$1 ?? 0}곳)',
      ];
      expect(
        unexpected,
        isEmpty,
        reason:
            '컴포넌트의 글자는 SmashLabel로 그린다 (docs: smash_label.dart). 예외가 꼭 필요하면 이 파일의 allowed에 이유와 함께 추가한다.',
      );
      for (final name in allowed.keys) {
        expect(
          found.containsKey(name),
          isTrue,
          reason: '허용 목록의 $name에서 더 이상 쓰지 않는다: 목록에서 지운다',
        );
      }
    });

    test(
      '모든 컴포넌트 파일이 SmashLabel을 쓰거나 글자를 그리지 않는다 (smash_label.dart가 아닌 곳에서 SmashLabel 호출 수 확인)',
      () {
        var total = 0;
        for (final file in files) {
          total += RegExp(
            r'(?<![A-Za-z0-9_$])SmashLabel\s*\(',
          ).allMatches(stripCommentsAndStrings(file.readAsStringSync())).length;
        }
        expect(total, greaterThan(40), reason: '컴포넌트가 SmashLabel로 글자를 그리고 있다');
      },
    );
  });

  /// 새 디자인(SmashTheme, 컴포넌트)으로 옮긴 화면 파일. 화면을 옮길 때마다(S단계) 여기에 더한다.
  /// 이 화면들은 날 `Text(`/`RichText(`와 옛 색(`AppColors`), 옛 테마(`core/theme`)를 쓰지 않는다.
  const migratedScreens = <String>[
    'lib/features/auth/page/login_page.dart', // S1a
    'lib/features/auth/page/signup_page.dart', // S1b
    'lib/features/home/page/home_page.dart', // S2b 홈 셸 (탭 안쪽 옛 화면은 LegacyTabFrame으로 감싼다)
    'lib/features/home/page/admin_menu_page.dart', // S2b 운영 탭
  ];

  group('교체한 화면 소스 전수 조사', () {
    test('목록의 파일이 실제로 있다 (이름이 바뀌어 검사가 비게 되는 것을 막는다)', () {
      for (final path in migratedScreens) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('날 Text(, Text.rich(, Text.new, RichText(을 쓰지 않는다 (글자는 SmashLabel로)', () {
      final offenders = <String>[
        for (final path in migratedScreens)
          if (rawTextCalls(File(path).readAsStringSync()).isNotEmpty) path,
      ];
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('옛 AppColors와 core/theme를 쓰지 않는다 (색은 SmashColors 토큰으로)', () {
      final offenders = <String>[
        for (final path in migratedScreens)
          for (final m in oldThemeUses(File(path).readAsStringSync()))
            '$path: ${m.group(0)}',
      ];
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}

/// 소스에서 옛 테마 사용(`AppColors` 이름, `core/theme/` import)을 찾는다. 주석과 문자열 안은 제외하지만
/// import 경로는 문자열이라서 따로 본다
List<RegExpMatch> oldThemeUses(String source) {
  final code = stripCommentsAndStrings(source);
  final names = RegExp(r'(?<![A-Za-z0-9_$])AppColors\b').allMatches(code);
  final imports = RegExp(
    r'''^\s*(?:import|export)\s+['"][^'"]*core/theme/[^'"]*['"]''',
    multiLine: true,
  ).allMatches(_withoutComments(source));
  return [...names, ...imports];
}

/// 주석만 지운다 (문자열은 남긴다)
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

/// 소스에서 주석과 문자열 리터럴을 지운다 (줄 수는 유지한다)
String stripCommentsAndStrings(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    final next = i + 1 < source.length ? source[i + 1] : '';
    if (c == '/' && next == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
    } else if (c == '/' && next == '*') {
      i += 2;
      while (i < source.length &&
          !(source[i] == '*' &&
              i + 1 < source.length &&
              source[i + 1] == '/')) {
        if (source[i] == '\n') out.write('\n');
        i++;
      }
      i += 2;
    } else if (c == "'" || c == '"') {
      final quote = c;
      out.write('""');
      i++;
      while (i < source.length && source[i] != quote) {
        if (source[i] == '\\') i++;
        if (i < source.length && source[i] == '\n') out.write('\n');
        i++;
      }
      i++;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// 주석과 문자열을 뺀 소스에서 날 글자 위젯 호출(`Text(`, `Text.rich(`, `Text.new`, `RichText(`) 위치들
List<RegExpMatch> rawTextCalls(String source) {
  final code = stripCommentsAndStrings(source);
  return RegExp(
    r'(?<![A-Za-z0-9_$])(?:Text\s*\(|Text\s*\.\s*rich\s*\(|Text\s*\.\s*new\b|RichText\s*\()',
  ).allMatches(code).toList();
}
