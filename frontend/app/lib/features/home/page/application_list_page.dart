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

    // 탭별 필터
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
      // Scaffold에 floatingActionButton 추가
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApplicantPage()),
        ).then((_) => ref.read(applicationProvider.notifier).load()),
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('지원서 관리'),
        actions: [
          // 폼 활성/비활성 토글
          if (form != null)
            Row(
              children: [
                Text(
                  form.isActive ? '접수 중' : '마감',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: form.isActive
                        ? AppColors.freeActivity
                        : AppColors.textTertiary,
                  ),
                ),
                Switch(
                  value: form.isActive,
                  activeColor: AppColors.freeActivity,
                  onChanged: (val) => ref
                      .read(applicationProvider.notifier)
                      .toggleForm(val),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '엑셀 내보내기',
            onPressed: _downloadExcel,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 검색
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '이름 또는 학번 검색',
                      hintStyle: const TextStyle(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ApplicationTabView(applications: pending),
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
        ).showSnackBar(const SnackBar(content: Text('다운로드에 실패했습니다.')));
      }
    }
  }
}

class _ApplicationTabView extends StatelessWidget {
  final List<ApplicationInfo> applications;

  const _ApplicationTabView({required this.applications});

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const Center(
        child: Text(
          '지원서가 없습니다.',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicationDetailPage(applicationId: app.id),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _statusColor(
                    app.status,
                  ).withOpacity(0.15),
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
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
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
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (app.memo != null && app.memo!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📝 ${app.memo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
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
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return AppColors.freeActivity;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}
