/// 새 디자인(SmashTheme, 컴포넌트)으로 옮긴 화면 파일. 화면을 옮길 때마다(S단계) 여기에 더한다.
/// 소스 스캔 지킴이(날 Text 금지, 옛 색 금지, 문구 규칙)가 이 목록을 함께 쓴다.
const migratedScreens = <String>[
  'lib/features/auth/page/login_page.dart', // S1a
  'lib/features/auth/page/signup_page.dart', // S1b
  'lib/features/home/page/home_page.dart', // S2b 홈 셸 (탭 안쪽 옛 화면은 LegacyTabFrame으로 감싼다)
  'lib/features/home/page/admin_menu_page.dart', // S2b 운영 탭
  'lib/features/home/page/profile_page.dart', // S3a-1b 내 정보 탭 내용(옛 설정 연결, 임시)
  'lib/features/home/page/schedule_tab.dart', // S3a-1 일정 탭의 달력 | 투표 전환
];
