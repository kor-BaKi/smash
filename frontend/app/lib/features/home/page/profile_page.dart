import 'package:flutter/material.dart';

import '../../../core/design/components/components.dart';
import 'legacy_tab_frame.dart';
import 'setting_page.dart';

/// 프로필 버튼으로 여는 "내 정보" 화면 (임시).
///
/// 내 정보를 새로 만드는 S6 전까지는 옛 설정 화면(알림 설정, 비밀번호 변경, 로그아웃, 탈퇴)을 그대로 연결한다.
/// 옛 설정 화면은 탭용이라 뒤로 가기가 없어서 이 틀이 앱바와 뒤로 가기를 더한다.
/// (옛 화면 안에도 "내 정보" 제목이 있어서 한동안 제목이 두 번 보인다. S6에서 이 파일을 새 화면으로 바꾼다)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.content = const SettingPage()});

  /// 본문 (갤러리에서 서버 없는 가짜 화면으로 바꿔 끼울 때만 넘긴다)
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return SmashScaffold(
      appBar: SmashAppBar(
        title: '내 정보',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: LegacyTabFrame(child: content),
    );
  }
}
