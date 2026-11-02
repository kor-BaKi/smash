import 'package:app/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('서버 주소는 HTTPS를 사용한다', () {
    expect(AppConstants.baseUrl, startsWith('https://'));
  });
}
