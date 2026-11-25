import 'dart:io';

import 'package:app/features/auth/auth_messages.dart';
import 'package:app/core/design/components/components.dart';
import 'package:app/dev/screens/bottom_bar_compare_states.dart';
import 'package:app/dev/screens/login_screen_states.dart';
import 'package:app/dev/screens/screen_conditions.dart';
import 'package:app/dev/screens/screen_gallery_app.dart';
import 'package:app/dev/screens/home_shell_states.dart';
import 'package:app/dev/screens/screen_registry.dart';
import 'package:app/dev/screens/signup_screen_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/screen_pump.dart';

/// 화면 상태 갤러리: 등록 규칙, 화면 열기, 조건 바꾸기, 가짜 서버로 직접 눌러 보기
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    await loadPretendard();
  });

  group('등록 목록 점검 (화면이 늘어나도 계속 지켜져야 하는 규칙)', () {
    test('화면 이름이 중복되지 않고 경로는 /로 시작한다', () {
      final names = screenGalleryEntries.map((e) => e.name).toList();
      expect(names, isNotEmpty);
      expect(names.toSet().length, names.length);
      for (final e in screenGalleryEntries) {
        expect(e.path, startsWith('/'), reason: e.name);
        expect(e.states, isNotEmpty, reason: e.name);
        expect(
          e.states.map((s) => s.label).toSet().length,
          e.states.length,
          reason: '${e.name}: 상태 이름 중복',
        );
      }
    });

    test('로그인 화면은 계획한 5가지 상태와 직접 눌러 보기를 가진다', () {
      final labels = loginScreenEntry.states.map((s) => s.label).toList();
      expect(labels.take(5), [
        '초기',
        '입력 오류',
        '제출 중',
        '서버·네트워크 오류',
        '제한·불가 (시도 횟수 초과)',
      ]);
      expect(labels.last, startsWith('직접 눌러 보기'));
      expect(loginScreenEntry.stubPaths, containsAll(['/signup', '/home']));
    });

    test('가입 화면은 계획한 상태와 직접 눌러 보기를 가지고 앱과 같은 경로를 쓴다', () {
      final labels = signupScreenEntry.states.map((s) => s.label).toList();
      expect(labels.take(5), [
        '1단계 초기',
        '입력 오류 (1단계)',
        '2단계 학번',
        '제출 중 (3단계)',
        '가입 실패 (3단계)',
      ]);
      expect(labels.last, startsWith('직접 눌러 보기'));
      expect(
        signupScreenEntry.routes,
        isNotNull,
        reason: '앱의 가입 경로(signupRoutes)를 그대로 쓴다',
      );
      expect(signupScreenEntry.routes!().map((r) => r.path), [
        '/signup',
        '/signup/id',
        '/signup/password',
      ]);
    });

    test('홈 셸은 계획한 상태와 직접 눌러 보기를 가지고 운영 메뉴 항목은 실제와 같다', () {
      final labels = homeShellScreenEntry.states.map((s) => s.label).toList();
      expect(labels.take(6), [
        '부원 홈 탭 (탭 2개, 조 미배정 안내)',
        '부원 일정 탭: 달력 (옛 화면 흉내)',
        '부원 일정 탭: 투표 (옛 화면 흉내: 자기 앱바가 겹침)',
        '임원 홈 탭 (탭 3개)',
        '임원 운영 탭 (10개 항목)',
        '프로필이 열린 모양 (옛 설정 화면 흉내)',
      ]);
      expect(labels.last, startsWith('직접 눌러 보기'));
      expect(screenGalleryEntries, contains(homeShellScreenEntry));
    });

    test('갤러리는 로그인, 가입 오류 문구를 베껴 적지 않고 AuthMessages를 쓴다 (문구가 어긋나지 않는다)', () {
      final messages = <String>{
        AuthMessages.loginOffline,
        AuthMessages.loginTimeout,
        AuthMessages.loginTooMany,
        AuthMessages.loginRejected,
        AuthMessages.loginServer,
        AuthMessages.loginUnknown,
        AuthMessages.signupRejected,
        AuthMessages.sessionExpired,
      };
      for (final path in [
        'lib/dev/screens/login_screen_states.dart',
        'lib/dev/screens/signup_screen_states.dart',
        'lib/features/home/provider/auth_provider.dart',
      ]) {
        final source = File(path).readAsStringSync();
        for (final message in messages) {
          expect(
            source.contains(message),
            isFalse,
            reason: '$path에 문구를 직접 적었다: $message',
          );
        }
      }
    });
  });

  group('ScreenHost: 조건이 화면에 실제로 전달된다', () {
    testWidgets('폭 320, 글자 2.0배, 키보드 300: 글자 배율, 키보드 높이, 안전 영역, 본문 높이', (
      tester,
    ) async {
      const c = ScreenConditions(
        width: 320,
        textScale: 2.0,
        keyboardHeight: 300,
      );
      await pumpScreen(
        tester,
        loginScreenEntry,
        loginScreenEntry.states.first,
        conditions: c,
      );

      final media = MediaQuery.of(
        tester.element(find.byType(SingleChildScrollView)),
      );
      expect(media.textScaler.scale(10), 20);
      // 본문 쪽 MediaQuery는 Scaffold가 키보드 높이를 이미 뺀 값이다: 본문 높이로 확인한다
      final body = tester.getSize(find.byType(SingleChildScrollView));
      expect(body.width, 320);
      expect(
        body.height,
        c.height - 300 - ScreenConditions.safeTop,
        reason: '키보드 위, 상태 표시줄 아래',
      );
      expect(
        tester.getTopLeft(find.byType(SingleChildScrollView)).dy,
        ScreenConditions.safeTop,
      );
    });

    testWidgets('키보드가 없으면 아래 안전 영역(34)만큼 비운다', (tester) async {
      const c = ScreenConditions(width: 360);
      await pumpScreen(
        tester,
        loginScreenEntry,
        loginScreenEntry.states.first,
        conditions: c,
      );
      final body = tester.getSize(find.byType(SingleChildScrollView));
      expect(
        body.height,
        c.height - ScreenConditions.safeTop - ScreenConditions.safeBottom,
      );
    });

    test('기기 높이는 폭에 맞춰 568, 640, 844다', () {
      expect(const ScreenConditions(width: 320).height, 568);
      expect(const ScreenConditions(width: 360).height, 640);
      expect(const ScreenConditions(width: 390).height, 844);
    });
  });

  group('갤러리 앱', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ScreenGalleryApp());
      await tester.pumpAndSettle();
    }

    testWidgets('화면 목록 → 상태 목록 → 상태 화면으로 들어가 조건을 바꿔도 오류가 없다', (tester) async {
      await open(tester);
      await tester.tap(find.text('로그인 (S1a)'));
      await tester.pumpAndSettle();
      for (final label in loginScreenEntry.states.map((s) => s.label)) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      await tester.tap(find.text('서버·네트워크 오류'));
      await tester.pumpAndSettle();
      expect(find.text(AuthMessages.loginOffline), findsOneWidget);

      for (final label in [
        '폭 320',
        '폭 390',
        '글자 2.0배',
        '글자 1.3배',
        '키보드 올라온 모양',
        '키보드 올라온 모양',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('하단 막대 비교: 목록에 상태 26개가 있고 상태를 열어 막대를 눌러 볼 수 있다', (
      tester,
    ) async {
      await open(tester);
      // 상태 목록이 길어서 한 화면에 다 안 들어간다. 모두 만들어지도록 화면을 길게 쓴다
      tester.view.physicalSize = const Size(420, 6000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('하단 막대 비교 (S3a 후속)'));
      await tester.pumpAndSettle();
      final labels = bottomBarCompareScreenEntry.states.map((s) => s.label);
      expect(labels.length, 26);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text('안 3 떠 있는 막대 · 임원 3탭'));
      await tester.pumpAndSettle();
      expect(find.byKey(barOuterKey), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^운영, ')));
      await tester.pumpAndSettle();
      expect(tester.widget<SmashAppBar>(find.byType(SmashAppBar)).title, '운영');
      expect(tester.takeException(), isNull);
    });

    testWidgets("하단 막대 비교: 구성 A'(5탭) 상태도 열리고 칸을 눌러 선택 표시가 움직인다", (
      tester,
    ) async {
      await open(tester);
      tester.view.physicalSize = const Size(420, 6000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('하단 막대 비교 (S3a 후속)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("구성 A' · 안 3 떠 있는 막대 · 임원 5탭"));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^내 기록, ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^내 정보, ')), findsOneWidget);
      final before = tester.getRect(find.byKey(barHighlightKey)).left;
      await tester.tap(find.bySemanticsLabel(RegExp('^내 기록, ')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(barHighlightKey)).left,
        greaterThan(before),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('입력 오류 상태: 안내가 있고, 빈 칸으로 로그인을 누르면 안내가 뜬다', (tester) async {
      await open(tester);
      await tester.tap(find.text('로그인 (S1a)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('두 칸을 비운 채'),
        findsOneWidget,
        reason: '목록에 해야 할 일이 적혀 있다',
      );
      await tester.tap(find.text('입력 오류'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SmashButton, '로그인'));
      await tester.pumpAndSettle();
      expect(find.text(AuthMessages.studentNoRequired), findsOneWidget);
    });

    testWidgets('가입 화면: 뒷 단계 상태(가입 실패)는 앞 단계가 쌓인 채로 열린다', (tester) async {
      await open(tester);
      await tester.tap(find.text('가입 3단계 (S1b)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가입 실패 (3단계)'));
      await tester.pumpAndSettle();
      expect(find.text(AuthMessages.signupRejected), findsOneWidget);
      expect(find.text('1단계로 가기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('가입 화면 직접 눌러 보기: 3단계 제출까지 가고 2초 뒤 가짜 서버가 결과를 돌려준다', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('가입 3단계 (S1b)'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('직접 눌러 보기').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'X');
      await tester.tap(find.widgetWithText(SmashButton, '다음').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2025');
      await tester.tap(find.widgetWithText(SmashButton, '다음').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'pw12');
      await tester.tap(find.widgetWithText(SmashButton, '가입하기'));
      await tester.pump();
      expect(
        find.text(AuthMessages.signupRejected),
        findsNothing,
        reason: '응답 전',
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(AuthMessages.signupRejected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('직접 눌러 보기: 가짜 서버가 2초 뒤에 학번에 따라 결과를 돌려준다', (tester) async {
      await open(tester);
      await tester.tap(find.text('로그인 (S1a)'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('직접 눌러 보기').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '2');
      await tester.enterText(find.byType(TextField).at(1), 'pw');
      await tester.tap(find.widgetWithText(SmashButton, '로그인'));
      await tester.pump();
      expect(
        find.text(AuthMessages.loginTooMany),
        findsNothing,
        reason: '아직 응답 전(제출 중)',
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text(AuthMessages.loginTooMany), findsOneWidget);
    });
  });
}
