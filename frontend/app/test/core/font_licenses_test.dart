import 'dart:io';

import 'package:app/core/licenses/font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<LicenseEntry>> _pretendardEntries() async {
  final all = await LicenseRegistry.licenses.toList();
  return all.where((e) => e.packages.contains('Pretendard')).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LicenseRegistry.reset();
    resetFontLicensesForTest();
  });

  group('글꼴 라이선스 등록', () {
    test('등록하면 Pretendard 라이선스 전문이 라이선스 화면 목록에 나온다', () async {
      registerFontLicenses();

      final entries = await _pretendardEntries();

      expect(entries, hasLength(1));
      final text = entries.single.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL Open Font License, Version 1.1'));
      expect(text, contains("Reserved Font Name 'Pretendard'"));
    });

    test('여러 번 호출해도 한 번만 등록한다', () async {
      registerFontLicenses();
      registerFontLicenses();
      registerFontLicenses();

      expect(await _pretendardEntries(), hasLength(1));
    });

    test('등록하지 않으면 목록에 없다 (등록 코드가 실제로 필요함을 확인)', () async {
      expect(await _pretendardEntries(), isEmpty);
    });
  });

  group('번들 글꼴 무결성 (OFL: 수정본은 Pretendard 이름을 쓸 수 없음)', () {
    // 공식 저장소 packages/pretendard/dist/public/static 의 원본 파일 크기 (v1.3.9)
    // 서브셋이나 변환을 하면 크기가 달라지므로 실수로 수정한 파일이 들어오는 것을 막는 안전장치.
    // 글꼴을 교체하거나 정리하면 이 목록도 함께 바꾼다.
    const officialSizes = <String, int>{
      'Pretendard-Regular.otf': 1574352,
      'Pretendard-Medium.otf': 1584068,
      'Pretendard-SemiBold.otf': 1583704,
      'Pretendard-Bold.otf': 1576660,
      'Pretendard-ExtraBold.otf': 1568512,
    };

    officialSizes.forEach((name, size) {
      test('$name 은 공식 원본과 크기가 같다', () {
        final file = File('assets/fonts/$name');

        expect(file.existsSync(), isTrue, reason: '$name 파일이 없음');
        expect(file.lengthSync(), size);
      });
    });
  });
}
