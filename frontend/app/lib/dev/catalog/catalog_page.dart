import 'package:flutter/material.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';

const catalogTextScales = [1.0, 1.3, 2.0];

/// 컴포넌트 목록
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, required this.entries});

  final List<CatalogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('컴포넌트 카탈로그')),
      body: entries.isEmpty
          ? const Center(child: Text('등록된 컴포넌트가 없어요'))
          : ListView(
              children: [
                for (final entry in entries)
                  ListTile(
                    title: Text(entry.name),
                    subtitle: Text(entry.description),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CatalogEntryPage(entry: entry),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// 한 컴포넌트의 모든 상태를 글자 1.0, 1.3, 2.0배로 한 화면에 나란히 보여준다.
class CatalogEntryPage extends StatelessWidget {
  const CatalogEntryPage({super.key, required this.entry});

  final CatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        padding: const EdgeInsets.all(SmashSpacing.md),
        children: [
          Text(entry.description, style: SmashText.caption),
          for (final scale in catalogTextScales) ...[
            const SizedBox(height: SmashSpacing.lg),
            Text('글자 $scale배', style: SmashText.heading),
            const SizedBox(height: SmashSpacing.sm),
            _ScaleBlock(entry: entry, scale: scale),
          ],
        ],
      ),
    );
  }
}

class _ScaleBlock extends StatelessWidget {
  const _ScaleBlock({required this.entry, required this.scale});

  final CatalogEntry entry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // 라벨은 배율과 무관하게 읽히도록 바깥에서 그리고, 컴포넌트만 확대한다
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final state in entry.states) ...[
          Padding(
            padding: const EdgeInsets.only(top: SmashSpacing.sm),
            child: Text(state.label, style: SmashText.caption),
          ),
          Container(
            key: ValueKey('${entry.name}|$scale|${state.label}'),
            margin: const EdgeInsets.only(top: SmashSpacing.xs),
            padding: const EdgeInsets.all(SmashSpacing.sm),
            decoration: BoxDecoration(
              color: SmashColors.surface,
              border: Border.all(color: SmashColors.line),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: Builder(builder: state.builder),
            ),
          ),
        ],
      ],
    );
  }
}
