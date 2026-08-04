import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('더보기')),
      body: const Center(
        child: Text(
          '준비 중입니다.',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
