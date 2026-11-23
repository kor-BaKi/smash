import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 화면 상태 갤러리에 올라가는 화면 한 개.
///
/// 새 화면(S단계)을 옮길 때는 이 클래스로 항목을 하나 만들고 `screen_registry.dart`에 한 줄을 더한다.
/// 상태는 프로바이더를 가짜로 바꿔(overrides) 만든다. 갤러리는 인증, 서버, Firebase 없이 화면만 띄운다.
class ScreenEntry {
  const ScreenEntry({
    required this.name,
    required this.description,
    required this.path,
    required this.builder,
    required this.states,
    this.stubPaths = const [],
  });

  final String name;
  final String description;

  /// 이 화면의 경로 (예: `/login`). 갤러리의 작은 라우터가 이 경로로 화면을 띄운다
  final String path;
  final WidgetBuilder builder;
  final List<ScreenState> states;

  /// 화면이 이동하는 다른 경로들 (예: `/signup`, `/home`). 갤러리에서는 자리 표시 화면으로 대신한다
  final List<String> stubPaths;
}

/// 한 화면의 한 상태.
class ScreenState {
  const ScreenState(this.label, {required this.overrides, this.hint});

  final String label;

  /// 이 상태를 만드는 프로바이더 대체 (새로 열 때마다 새 가짜가 만들어진다)
  final List<Override> overrides;

  /// 화면 안에서 직접 해야 만들어지는 상태일 때, 기기에서 무엇을 해 보면 되는지 (예: "빈 칸으로 로그인을 눌러 보세요")
  final String? hint;
}
