import 'package:flutter/material.dart';

import 'legacy_tab_frame.dart';
import 'setting_page.dart';

/// "내 정보" 탭의 내용 (임시).
///
/// 내 정보를 새로 만드는 S6 전까지는 옛 설정 화면(알림 설정, 비밀번호 변경, 로그아웃, 탈퇴)을 그대로 보여 준다.
/// 탭의 첫 화면이라 뒤로 가기 화살표가 없고, 앱바(제목 "내 정보")는 셸이 그린다.
/// (옛 화면 안에도 "내 정보" 제목이 있어서 한동안 제목이 두 번 보인다. S6에서 이 파일을 새 화면으로 바꾼다)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegacyTabFrame(child: SettingPage());
}
