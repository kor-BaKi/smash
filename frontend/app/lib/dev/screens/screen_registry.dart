import 'login_screen_states.dart';
import 'screen_entry.dart';
import 'signup_screen_states.dart';

/// 화면 상태 갤러리에 올라간 화면 목록.
/// 화면을 옮길 때마다 `ScreenEntry`를 만들어 여기에 한 줄을 더한다.
final List<ScreenEntry> screenGalleryEntries = [
  loginScreenEntry,
  signupScreenEntry,
];
