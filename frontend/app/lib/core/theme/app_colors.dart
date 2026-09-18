import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 중앙 컬러 시스템.
///
/// 특정 컬러를 변경하고 싶다면 이 파일의 값만 수정하면
/// 전체 화면에 반영된다.
class AppColors {
  AppColors._();

  // ── 배경 (Background / Surface) ──
  static const bg = Color(0xFF111111);
  static const card = Color(0xFF1C1C1C);
  static const card2 = Color(0xFF242424);
  static const border = Color(0xFF2A2A2A);

  // ── 브랜드 포인트 컬러 ──
  // lime: 브랜드 primary 액션(버튼/선택 상태/강조)
  // green: 긍정/성공/자유 활동 상태
  // coral: 부정/위험/에러 상태
  static const lime = Color(0xFFCDD04F);
  static const green = Color(0xFF5EB58C);
  static const coral = Color(0xFFD06C52);
  static const primaryDeep = Color(0xFF9DA030);
  static const primaryBg = Color(0xFF2A2C10);

  // ── 텍스트 / 아이콘 ──
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFF8A8A8A);
  static const darkGray = Color(0xFF555555);
  // 브랜드 포인트 컬러(lime 등) 위에 올라가는 텍스트/아이콘 색
  static const onPrimary = Color(0xFF111111);

  // ── 오버레이 / 스크림 ──
  // 카드/이미지 위에 얇게 덮이는 어두운 톤(withValues로 투명도 조절), 전체 화면 배경으로도 사용
  static const overlay = Color(0xFF000000);

  // ── 상태 배지 ──
  static const greenTag = Color(0x335EB58C);
  static const coralTag = Color(0x33D06C52);
  static const amberTag = Color(0x33FFB432);
  static const grayTag = Color(0xFF2A2A2A);
  static const greenTagText = Color(0xFF5EB58C);
  static const coralTagText = Color(0xFFD06C52);
  static const amberTagText = Color(0xFFC8901A);
  static const grayTagText = Color(0xFF8A8A8A);

  // ── 차트/목록 구분용 보조 액센트 ──
  // 투표 옵션, 그룹 카드 등 여러 항목을 색으로 구분할 때 순환 사용
  static const accentViolet = Color(0xFF7B5EA7);
  static const accentBlue = Color(0xFF3A7BD5);
  static const accentPurple = Color(0xFF7C3AED);
  static const accentCyan = Color(0xFF0891B2);
  static const accentPink = Color(0xFFDB2777);
}
