import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 개발용 카탈로그(lib/dev)는 앱 코드에서 가져오지 않아야 릴리스 빌드에 들어가지 않는다.
// 반대로 카탈로그는 Firebase, 인증, 화면 코드에 의존하지 않아야 어디서든 띄울 수 있다.
void main() {
  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

  test('앱 코드(lib/dev 밖)는 lib/dev를 가져오지 않는다', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib')) {
      if (file.path.startsWith('lib/dev/')) continue;
      for (final match in importPattern.allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        if (target.contains('dev/catalog') || target.startsWith('package:app/dev/')) {
          offenders.add('${file.path} → $target');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('앱의 main.dart와 app.dart는 카탈로그를 언급하지 않는다', () {
    for (final path in ['lib/main.dart', 'lib/app.dart']) {
      expect(File(path).readAsStringSync().contains('catalog'), isFalse, reason: path);
    }
  });

  test('카탈로그는 Firebase, 인증, 화면(features) 코드에 의존하지 않는다', () {
    final offenders = <String>[];
    for (final file in dartFiles('lib/dev')) {
      for (final match in importPattern.allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        if (target.contains('firebase') ||
            target.contains('features/') ||
            target.contains('core/api')) {
          offenders.add('${file.path} → $target');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('진입점 파일이 존재한다', () {
    expect(File('lib/dev/catalog_main.dart').existsSync(), isTrue);
  });
}
