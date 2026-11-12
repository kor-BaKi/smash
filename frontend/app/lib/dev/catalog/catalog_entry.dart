import 'package:flutter/widgets.dart';

/// 카탈로그에서 보여줄 컴포넌트 한 종류.
class CatalogEntry {
  const CatalogEntry({
    required this.name,
    required this.description,
    required this.states,
  });

  final String name;
  final String description;

  /// 보여줄 상태 목록. 해당 없는 상태(예: 버튼의 에러)는 넣지 않는다.
  final List<CatalogState> states;
}

/// 한 상태의 모습. [builder]는 화면 너비 안에서 그려진다.
class CatalogState {
  const CatalogState(this.label, this.builder);

  /// 기본, 눌림, 비활성, 로딩, 에러 등
  final String label;
  final WidgetBuilder builder;
}
