// 개발용 컴포넌트 카탈로그 진입점.
//
//   flutter run -t lib/dev/catalog_main.dart
//
// 앱의 main.dart에서 이 파일을 가져오지 않으므로 릴리스 빌드에는 포함되지 않는다.
// (test/dev/catalog_isolation_test.dart가 이를 검사한다)
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'catalog/catalog_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const CatalogApp());
}
