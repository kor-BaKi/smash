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

  // SmashForcePressed는 카탈로그와 테스트에서 "눌림" 모양을 손가락 없이 보여주기 위한 것이다.
  // 앱 화면이 쓰면 화면의 버튼이 항상 눌린 모양이 되므로, 정의된 곳(lib/core/design)과
  // 카탈로그(lib/dev) 밖에서는 이름도 import도 나오지 않아야 한다. (components.dart 같은
  // 묶음 파일로 가져와도 쓰려면 이름을 적어야 하므로 이름 검사로 걸러진다)
  group('SmashForcePressed 사용 범위', () {
    bool mentionsForcePressed(File file) {
      final text = file.readAsStringSync();
      return text.contains('SmashForcePressed') || text.contains('smash_force_pressed');
    }

    bool isAllowedLocation(File file) =>
        file.path.startsWith('lib/dev/') || file.path.startsWith('lib/core/design/');

    test('lib/dev와 lib/core/design 밖의 어떤 파일도 참조하지 않는다', () {
      final offenders = [
        for (final file in dartFiles('lib'))
          if (!isAllowedLocation(file) && mentionsForcePressed(file)) file.path,
      ];

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('검사가 실제로 동작한다: 허용된 위치에는 참조가 있다 (경로가 바뀌어 검사가 비게 되는 것을 막음)', () {
      final allowed = [
        for (final file in dartFiles('lib'))
          if (isAllowedLocation(file) && mentionsForcePressed(file)) file.path,
      ];

      expect(allowed, contains('lib/core/design/components/smash_force_pressed.dart'));
      expect(allowed.any((path) => path.startsWith('lib/dev/')), isTrue);
    });
  });

  test('진입점 파일이 존재한다', () {
    expect(File('lib/dev/catalog_main.dart').existsSync(), isTrue);
  });
}
