import 'package:flutter/material.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/smash_theme.dart';
import '../../../core/design/tokens.dart';
import 'activity_admin_page.dart';
import 'application_form_page.dart';
import 'application_list_page.dart';
import 'attendance_page.dart';
import 'dues_page.dart';
import 'free_period_page.dart';
import 'group_management_page.dart';
import 'invite_code_page.dart';
import 'member_management_page.dart';
import 'schedule_page.dart';

/// 운영 메뉴의 항목 하나. 누르면 [builder]가 만드는 (아직 옛 디자인인) 화면이 위에 쌓인다.
class AdminMenuItem {
  const AdminMenuItem({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

class AdminMenuSection {
  const AdminMenuSection({required this.title, required this.items});

  final String title;
  final List<AdminMenuItem> items;
}

/// 운영 메뉴 (이전의 왼쪽 위 메뉴 Drawer와 같은 구역, 같은 항목, 같은 순서). 10개.
final List<AdminMenuSection> adminMenuSections = [
  AdminMenuSection(
    title: '회원 운영',
    items: [
      AdminMenuItem(
        icon: Icons.person_outline,
        label: '부원 관리',
        builder: (_) => const MemberManagementPage(),
      ),
      AdminMenuItem(
        icon: Icons.groups_outlined,
        label: '조 편성 관리',
        builder: (_) => const GroupManagementPage(),
      ),
      AdminMenuItem(
        icon: Icons.assignment_outlined,
        label: '지원서 관리',
        builder: (_) => const ApplicationListPage(),
      ),
      AdminMenuItem(
        icon: Icons.edit_document,
        label: '지원 폼 관리',
        builder: (_) => const ApplicationFormPage(),
      ),
      AdminMenuItem(
        icon: Icons.key_outlined,
        label: '가입코드 관리',
        builder: (_) => const InviteCodePage(),
      ),
    ],
  ),
  AdminMenuSection(
    title: '활동 운영',
    items: [
      AdminMenuItem(
        icon: Icons.calendar_month_outlined,
        label: '정규활동 일정',
        builder: (_) => const SchedulePage(),
      ),
      AdminMenuItem(
        icon: Icons.event_note_outlined,
        label: '날짜별 활동 관리',
        builder: (_) => const ActivityAdminPage(),
      ),
      AdminMenuItem(
        icon: Icons.fact_check_outlined,
        label: '출석 현황',
        builder: (_) => const AttendancePage(),
      ),
      AdminMenuItem(
        icon: Icons.sports_tennis_outlined,
        label: '자유활동 기간 설정',
        builder: (_) => const FreePeriodPage(),
      ),
    ],
  ),
  AdminMenuSection(
    title: '재정 운영',
    items: [
      AdminMenuItem(
        icon: Icons.wallet_outlined,
        label: '회비 관리',
        builder: (_) => const DuesPage(),
      ),
    ],
  ),
];

/// 운영진의 "운영" 탭 화면. 운영 기능 10개를 구역별 목록으로 보여 준다.
///
/// 항목을 누르면 지금처럼 옛 화면이 위에 쌓인다 (그 화면들은 운영 화면을 옮기는 S8에서 교체한다).
class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key, this.customSections});

  /// 테스트와 갤러리에서 항목을 바꿔 끼울 때만 넘긴다 (없으면 [adminMenuSections])
  final List<AdminMenuSection>? customSections;

  List<AdminMenuSection> get sections => customSections ?? adminMenuSections;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SmashTheme.light(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: SmashSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SmashSpacing.md,
              SmashSpacing.md,
              SmashSpacing.md,
              SmashSpacing.xs,
            ),
            child: Semantics(
              header: true,
              child: const SmashLabel('운영', style: SmashText.title),
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: SmashSpacing.sm),
            SmashSectionHeader(
              title: section.title,
              style: SmashSectionHeaderStyle.label,
            ),
            for (final item in section.items)
              SmashListRow(
                title: item.label,
                leading: ExcludeSemantics(
                  child: Icon(
                    item.icon,
                    color: SmashColors.textSecondary,
                    size: 24,
                  ),
                ),
                trailing: const ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    color: SmashColors.textSecondary,
                  ),
                ),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: item.builder)),
              ),
          ],
        ],
      ),
    );
  }
}
