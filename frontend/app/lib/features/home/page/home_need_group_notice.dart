import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'availability_page.dart';

/// 조가 아직 배정되지 않은 회원(운영진)에게 보이는 홈 탭 안내.
///
/// 옛 디자인(어두운 화면) 그대로이고, 홈 탭을 새 디자인으로 바꾸는 S3에서 교체한다.
/// (홈 셸을 새 디자인으로 바꿀 때 `home_page.dart` 안에 있던 것을 그대로 옮겼다. 운영진 안내 문구만 Drawer가 없어져서 바뀌었다)
class NeedGroupNotice extends StatelessWidget {
  const NeedGroupNotice({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 32,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '아직 조가 배정되지 않았어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin ? '운영 탭에서 운영 기능을 이용할 수 있습니다.' : '참여 가능한 요일을 먼저 제출해주세요.',
              style: const TextStyle(fontSize: 14, color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvailabilityPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '가능 요일 제출하기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
