import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱에 번들한 글꼴의 라이선스를 Flutter 라이선스 화면(showLicensePage)에 등록한다.
///
/// SIL OFL 1.1 은 글꼴을 소프트웨어와 함께 배포할 때 저작권 고지와 라이선스 전문을
/// 각 사본에 포함하라고 요구한다. 전문은 라이선스 화면을 열 때 읽으므로
/// 앱 시작 속도에는 영향이 없다.
const String pretendardLicenseAsset = 'assets/licenses/Pretendard-OFL.txt';

bool _registered = false;

/// 여러 번 호출해도 한 번만 등록한다.
void registerFontLicenses() {
  if (_registered) return;
  _registered = true;

  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(pretendardLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Pretendard'], text);
  });
}

/// 테스트에서 등록 상태를 되돌린다.
@visibleForTesting
void resetFontLicensesForTest() {
  _registered = false;
}
