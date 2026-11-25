import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/migrated_screens.dart';

/// 문구 규칙 지킴이 (소스 스캔). 사용자에게 보이는 글자(문자열 리터럴)에서 용어 사전과 말투 규칙을 어기는 표현을 찾는다.
///
/// 대상: 새 디자인으로 옮긴 화면 파일([migratedScreens]), `AuthMessages`, `ErrorMessages`.
/// 화면을 옮길 때마다 [migratedScreens]에 더하면 이 지킴이가 자동으로 지킨다.
///
/// 금지 표현은 용어 사전(메모리 project-smash-ia-decisions)에서 가져왔다:
/// - 가입(회원가입 대신), 부원(회원, 구성원 대신), 호차/조(그룹이라는 말은 쓰지 않음), "부원 직접 등록"("지원자 등록" 대신)
/// - 말투는 해요체: 합쇼체 어미(~습니다, ~ㅂ니다, ~습니까, ~십시오)와 붙여 쓴 "해주세요"는 쓰지 않는다 ("해 주세요")
///
/// 오탐이나 아직 못 고친 곳은 [exceptions]에 `파일 → {문자열 일부: 이유}`로 적는다. 이유가 없는 예외는 허용하지 않고,
/// 예외가 더는 필요 없어지면(고쳐졌으면) 테스트가 실패해서 목록에서 지우게 한다.
void main() {
  const files = <String>[
    ...migratedScreens,
    'lib/features/auth/auth_messages.dart',
    'lib/core/error/error_messages.dart',
  ];

  /// 금지 표현: 이름 → (찾는 식, 대신 쓸 말)
  final forbidden = <String, (RegExp, String)>{
    '회원': (RegExp('회원'), '부원 (가입: "회원가입" 대신 "가입")'),
    '구성원': (RegExp('구성원'), '부원'),
    '그룹': (RegExp('그룹'), '호차(택시 한 대 단위) 또는 조'),
    '지원자 등록': (RegExp('지원자\\s*등록'), '부원 직접 등록'),
    '합쇼체(~니다)': (RegExp('니다(?![가-힣])'), '해요체(~해요, ~돼요)'),
    '합쇼체(~니까)': (RegExp('니까(?![가-힣])'), '해요체(~해요?)'),
    '합쇼체(~십시오)': (RegExp('십시오'), '~해 주세요'),
    '붙여 쓴 해주세요': (RegExp('해주(세요|시|실)'), '"해 주세요"로 띄어 쓴다'),
  };

  /// 예외: 파일 → {문자열 일부: 이유}. 오탐은 이유를 적고, 아직 못 고친 곳은 고칠 단계를 적는다
  const exceptions = <String, Map<String, String>>{
    'lib/features/home/page/home_page.dart': {
      '로그인이 필요합니다':
          '아직 고치지 않음(합쇼체). S3a에서 홈 탭 파일을 다시 쓸 때 "로그인이 필요해요"로 바꾸고 이 예외를 지운다',
    },
    'lib/features/home/page/admin_menu_page.dart': {
      '회원 운영':
          '아직 고치지 않음(용어 사전은 부원). S3a에서 운영 탭을 다시 쓸 때 "부원 운영"으로 바꾸고 이 예외를 지운다',
    },
  };

  /// 소스에서 문자열 리터럴 내용만 뽑는다 (주석은 건너뛴다). 보간(`$x`, `${...}`)은 그대로 둔다
  List<String> literals(String source) {
    final out = <String>[];
    var i = 0;
    final n = source.length;
    while (i < n) {
      final c = source[i];
      if (c == '/' && i + 1 < n && source[i + 1] == '/') {
        while (i < n && source[i] != '\n') {
          i++;
        }
      } else if (c == '/' && i + 1 < n && source[i + 1] == '*') {
        final end = source.indexOf('*/', i + 2);
        i = end < 0 ? n : end + 2;
      } else if (c == "'" || c == '"') {
        final triple = i + 2 < n && source[i + 1] == c && source[i + 2] == c;
        final raw = i > 0 && source[i - 1] == 'r';
        final quote = triple ? c * 3 : c;
        i += quote.length;
        final start = i;
        while (i < n) {
          if (!raw && source[i] == '\\') {
            i += 2;
            continue;
          }
          if (source.startsWith(quote, i)) break;
          if (!triple && source[i] == '\n') break;
          i++;
        }
        out.add(source.substring(start, i > n ? n : i));
        i += quote.length;
      } else {
        i++;
      }
    }
    return out;
  }

  /// 파일의 위반 목록 (예외로 걸러진 것은 [used]에 기록한다)
  List<String> violations(
    String path,
    String source, {
    Map<String, String> allow = const {},
    Set<String>? used,
  }) {
    final result = <String>[];
    for (final text in literals(source)) {
      for (final entry in forbidden.entries) {
        if (!entry.value.$1.hasMatch(text)) continue;
        final key = allow.keys.where(text.contains).firstOrNull;
        if (key != null) {
          used?.add('$path|$key');
          continue;
        }
        result.add('$path: "${entry.key}" → ${entry.value.$2}: "$text"');
      }
    }
    return result;
  }

  test('대상 파일이 실제로 있다 (이름이 바뀌어 검사가 비게 되는 것을 막는다)', () {
    for (final path in files) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('문자열 리터럴 추출기: 주석과 코드는 건너뛰고 문자열만 뽑는다', () {
    const source = '''
// "주석 안의 회원"
const a = '회원가입'; // 뒤의 주석 "회원"
/* "블록 주석 회원" */
final b = "해주세요 \\" 이어짐";
final c = r'원시 \\ 문자열';
final d = \'\'\'여러 줄
회원\'\'\';
''';
    expect(literals(source), ['회원가입', '해주세요 \\" 이어짐', '원시 \\ 문자열', '여러 줄\n회원']);
  });

  test('금지 표현을 찾아낸다 (식마다 잡히는 글자와 안 잡히는 글자)', () {
    String? hit(String text) {
      final v = violations('x.dart', "const t = '$text';");
      return v.isEmpty ? null : v.first;
    }

    for (final bad in [
      '회원가입',
      '회원 운영',
      '구성원',
      '그룹 편성',
      '지원자 등록',
      '로그인이 필요합니다',
      '입력해야 합니다.',
      '삭제하시겠습니까',
      '입력하십시오',
      '입력해주세요',
      '확인해주시면',
    ]) {
      expect(hit(bad), isNotNull, reason: bad);
    }
    for (final good in [
      '가입',
      '부원 운영',
      '호차를 정해 주세요',
      '부원 직접 등록',
      '로그인이 필요해요',
      '입력해 주세요.',
      '이미 가입한 학번이에요.',
      '아니다를 쓰지 않는다',
    ]) {
      expect(hit(good), isNull, reason: good);
    }
  });

  test('대상 파일의 사용자용 글자에 금지 표현이 없다 (예외는 이유가 적힌 것뿐)', () {
    final used = <String>{};
    final all = <String>[
      for (final path in files)
        ...violations(
          path,
          File(path).readAsStringSync(),
          allow: exceptions[path] ?? const {},
          used: used,
        ),
    ];
    expect(all, isEmpty, reason: '\n${all.join('\n')}');
  });

  test('예외 목록은 이유가 있고 아직 필요한 것만 남아 있다', () {
    final used = <String>{};
    for (final path in files) {
      violations(
        path,
        File(path).readAsStringSync(),
        allow: exceptions[path] ?? const {},
        used: used,
      );
    }
    for (final entry in exceptions.entries) {
      expect(files, contains(entry.key), reason: '대상이 아닌 파일의 예외');
      for (final item in entry.value.entries) {
        expect(
          item.value.trim().length,
          greaterThan(10),
          reason: '이유가 없다: ${item.key}',
        );
        expect(
          used,
          contains('${entry.key}|${item.key}'),
          reason: '더는 필요 없는 예외라서 지운다: ${entry.key} "${item.key}"',
        );
      }
    }
  });
}
