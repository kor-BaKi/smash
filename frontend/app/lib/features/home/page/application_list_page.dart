import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/application_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/application_model.dart';
import '../provider/application_provider.dart';
import 'applicant_page.dart';
import 'application_detail_page.dart';

class ApplicationListPage extends ConsumerStatefulWidget {
  const ApplicationListPage({super.key});

  @override
  ConsumerState<ApplicationListPage> createState() =>
      _ApplicationListPageState();
}

class _ApplicationListPageState extends ConsumerState<ApplicationListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(applicationProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationProvider);
    final form = state.form;

    final pending = state.applications
        .where(
          (a) =>
              a.status == 'PENDING' &&
              (a.name.contains(_searchQuery) ||
                  a.studentNo.contains(_searchQuery)),
        )
        .toList();
    final accepted = state.applications
        .where(
          (a) =>
              a.status == 'ACCEPTED' &&
              (a.name.contains(_searchQuery) ||
                  a.studentNo.contains(_searchQuery)),
        )
        .toList();
    final rejected = state.applications
        .where(
          (a) =>
              a.status == 'REJECTED' &&
              (a.name.contains(_searchQuery) ||
                  a.studentNo.contains(_searchQuery)),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.lime,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApplicantPage()),
        ).then((_) => ref.read(applicationProvider.notifier).load()),
        child: const Icon(
          Icons.person_add_outlined,
          color: Color(0xFF111111),
        ),
      ),
      appBar: AppBar(
        title: const Text('지원서 관리'),
        actions: [
          if (form != null)
            Row(
              children: [
                Text(
                  form.isActive ? '접수 중' : '마감',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: form.isActive
                        ? AppColors.green
                        : AppColors.gray,
                  ),
                ),
                Switch(
                  value: form.isActive,
                  activeColor: AppColors.lime,
                  activeTrackColor: AppColors.lime.withValues(alpha: 0.3),
                  inactiveThumbColor: AppColors.darkGray,
                  inactiveTrackColor: AppColors.card2,
                  onChanged: (val) => ref
                      .read(applicationProvider.notifier)
                      .toggleForm(val),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.lime),
            tooltip: '엑셀 내보내기',
            onPressed: _downloadExcel,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.lime,
          unselectedLabelColor: AppColors.darkGray,
          indicatorColor: AppColors.lime,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: '미처리 (${pending.length})'),
            Tab(text: '합격 (${accepted.length})'),
            Tab(text: '불합격 (${rejected.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: '이름 또는 학번 검색',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ApplicationTabView(
                        applications: pending,
                        showAcceptAll: true,
                      ),
                      _ApplicationTabView(applications: accepted),
                      _ApplicationTabView(applications: rejected),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _downloadExcel() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('엑셀 파일을 준비 중입니다...')));
      final bytes = await ApplicationApi.exportToExcel();
      await FlutterFileSaver().writeFileAsBytes(
        fileName: 'applications.xlsx',
        bytes: Uint8List.fromList(bytes),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('엑셀 파일이 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('다운로드에 실패했습니다. $e')));
      }
    }
  }
}

class _ApplicationTabView extends ConsumerWidget {
  final List<ApplicationInfo> applications;
  final bool showAcceptAll;

  const _ApplicationTabView({
    required this.applications,
    this.showAcceptAll = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (applications.isEmpty) {
      return const Center(
        child: Text('지원서가 없습니다.', style: TextStyle(color: AppColors.gray)),
      );
    }

    return Column(
      children: [
        if (showAcceptAll)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmAcceptAll(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  '미처리 ${applications.length}명 전체 합격',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ApplicationDetailPage(applicationId: app.id),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _statusColor(
                          app.status,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          app.name.characters.first,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _statusColor(app.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  app.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      app.status,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      999,
                                    ),
                                  ),
                                  child: Text(
                                    app.statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(app.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${app.studentNo} · ${app.department}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            ),
                            if (app.memo != null &&
                                app.memo!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '📝 ${app.memo}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.darkGray,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAcceptAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '전체 합격 처리',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '미처리 ${applications.length}명을 모두 합격 처리할까요?',
          style: const TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.gray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '전체 합격',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await ref
          .read(applicationProvider.notifier)
          .acceptAll();
      if (context.mounted) {
        final accepted = result['accepted'] ?? 0;
        final skipped = result['skipped'] ?? 0;
        String msg = '$accepted명 합격 처리되었습니다.';
        if (skipped > 0) {
          msg += '\n($skipped명은 이미 등록된 학번으로 users 등록 제외)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return AppColors.green;
      case 'REJECTED':
        return AppColors.coral;
      default:
        return AppColors.lime;
    }
  }
}
