import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/design/smash_theme.dart';
import '../../core/design/tokens.dart';
import 'screen_conditions.dart';
import 'screen_entry.dart';
import 'screen_host.dart';
import 'screen_registry.dart';

/// 개발용 화면 상태 갤러리. 인증, 서버, Firebase 없이 화면의 상태들을 기기 크기, 글자 배율, 키보드를 바꿔 가며 본다.
///
///   flutter run -t lib/dev/screen_gallery_main.dart
class ScreenGalleryApp extends StatelessWidget {
  const ScreenGalleryApp({super.key, this.entries});

  final List<ScreenEntry>? entries;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASH 화면 갤러리',
      theme: SmashTheme.light(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: _EntryListPage(entries: entries ?? screenGalleryEntries),
    );
  }
}

class _EntryListPage extends StatelessWidget {
  const _EntryListPage({required this.entries});

  final List<ScreenEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('화면 상태 갤러리')),
      body: ListView(
        children: [
          for (final entry in entries)
            ListTile(
              title: Text(entry.name),
              subtitle: Text(entry.description),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _StateListPage(entry: entry),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StateListPage extends StatelessWidget {
  const _StateListPage({required this.entry});

  final ScreenEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        children: [
          for (final state in entry.states)
            ListTile(
              title: Text(state.label),
              subtitle: state.hint == null ? null : Text(state.hint!),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScreenStatePage(entry: entry, state: state),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 한 상태를 조건(폭, 글자 배율, 키보드)을 바꿔 가며 보는 화면
class ScreenStatePage extends StatefulWidget {
  const ScreenStatePage({super.key, required this.entry, required this.state});

  final ScreenEntry entry;
  final ScreenState state;

  @override
  State<ScreenStatePage> createState() => _ScreenStatePageState();
}

class _ScreenStatePageState extends State<ScreenStatePage> {
  ScreenConditions _conditions = const ScreenConditions();

  @override
  Widget build(BuildContext context) {
    final c = _conditions;
    return Scaffold(
      appBar: AppBar(title: Text(widget.state.label)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SmashSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.state.hint != null)
                  Text(widget.state.hint!, style: SmashText.caption),
                Wrap(
                  spacing: SmashSpacing.sm,
                  children: [
                    for (final w in ScreenConditions.widths)
                      ChoiceChip(
                        label: Text('폭 ${w.toInt()}'),
                        selected: c.width == w,
                        onSelected: (_) =>
                            setState(() => _conditions = c.copyWith(width: w)),
                      ),
                  ],
                ),
                Wrap(
                  spacing: SmashSpacing.sm,
                  children: [
                    for (final s in ScreenConditions.textScales)
                      ChoiceChip(
                        label: Text('글자 $s배'),
                        selected: c.textScale == s,
                        onSelected: (_) => setState(
                          () => _conditions = c.copyWith(textScale: s),
                        ),
                      ),
                    FilterChip(
                      label: const Text('키보드 올라온 모양'),
                      selected: c.keyboardHeight > 0,
                      onSelected: (on) => setState(
                        () => _conditions = c.copyWith(
                          keyboardHeight: on ? ScreenConditions.keyboardUp : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(SmashSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: SmashColors.border),
                  ),
                  width: c.width,
                  height: c.height,
                  child: ClipRect(
                    child: ScreenHost(
                      // 상태나 조건이 바뀔 때마다 새 가짜 프로바이더로 다시 시작한다
                      key: ValueKey(
                        '${widget.entry.name}|${widget.state.label}',
                      ),
                      entry: widget.entry,
                      state: widget.state,
                      conditions: c,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
