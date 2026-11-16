import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/design/typography.dart';
import 'catalog_entry.dart';
import 'catalog_state_host.dart';

const _longText = '이번 달에 참여하지 못한 날을 이월로 채울 수 있어요. '
    '이월은 다음 달 정규 활동에 한 번 빠져도 괜찮도록 미리 쌓아 두는 횟수예요. ';

final sheetEntry = CatalogEntry(
  name: 'SmashSheet',
  description: '아래에서 올라오는 시트. 눌러서 열어 보세요. 키보드, 긴 내용, 닫기 방지 상태를 직접 확인할 수 있다.',
  states: [
    CatalogState(
      '기본 (제목 + 내용)',
      (context) => SmashButton(
        label: '시트 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSheet<void>(
          context: context,
          title: '이동 방식',
          builder: (_) => const Text('같이 가요 / 따로 가요 중에서 골라요.', style: SmashText.body),
        ),
      ),
    ),
    CatalogState(
      '긴 내용 (시트 안에서 스크롤)',
      (context) => SmashButton(
        label: '긴 시트 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSheet<void>(
          context: context,
          title: '이월 안내',
          builder: (_) => Text(_longText * 12, style: SmashText.body),
        ),
      ),
    ),
    CatalogState(
      '입력창 (키보드가 올라오면 시트가 키보드 위로)',
      (context) => SmashButton(
        label: '입력 시트 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSheet<void>(
          context: context,
          title: '메모',
          builder: (_) => const SmashTextField(label: '메모', hint: '내용을 적어 주세요'),
        ),
      ),
    ),
    CatalogState(
      '닫기 방지 (바깥 누르기, 끌어내리기 꺼짐)',
      (context) => SmashButton(
        label: '닫기 방지 시트 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSheet<void>(
          context: context,
          title: '날짜 고르기',
          isDismissible: false,
          enableDrag: false,
          builder: (sheetContext) => SmashButton(
            label: '선택 완료',
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
    CatalogState(
      interactiveStateLabel,
      (_) => CatalogStateHost<String>(
        initial: '아직 고르지 않았어요',
        describe: (value) => value,
        builder: (context, value, onChanged) => SmashButton(
          label: '고르기',
          variant: SmashButtonVariant.secondary,
          onPressed: () async {
            final picked = await showSmashSheet<String>(
              context: context,
              title: '이동 방식',
              builder: (sheetContext) => Column(
                children: [
                  for (final option in const ['같이 가요', '따로 가요'])
                    SmashListRow(title: option, onTap: () => Navigator.of(sheetContext).pop(option)),
                ],
              ),
            );
            onChanged(picked ?? '닫았어요 (고르지 않음)');
          },
        ),
      ),
    ),
  ],
);

final dialogEntry = CatalogEntry(
  name: 'SmashDialog',
  description: '가운데 뜨는 대화상자. 눌러서 열어 보세요. 확인은 위, 취소는 아래로 세로로 쌓인다.',
  states: [
    CatalogState(
      '확인 / 취소 (결과 표시)',
      (_) => CatalogStateHost<String>(
        initial: '아직 안 눌렀어요',
        describe: (value) => value,
        builder: (context, value, onChanged) => SmashButton(
          label: '확인 대화상자 열기',
          variant: SmashButtonVariant.secondary,
          onPressed: () async {
            final ok = await showSmashConfirm(
              context: context,
              title: '신청을 보낼까요?',
              message: '보낸 뒤에는 수정할 수 없어요.',
              confirmLabel: '보내기',
            );
            onChanged(ok ? '확인을 눌렀어요' : '취소했어요');
          },
        ),
      ),
    ),
    CatalogState(
      '되돌리기 어려운 일 (빨간 확인)',
      (_) => CatalogStateHost<String>(
        initial: '아직 안 눌렀어요',
        describe: (value) => value,
        builder: (context, value, onChanged) => SmashButton(
          label: '삭제 대화상자 열기',
          variant: SmashButtonVariant.secondary,
          onPressed: () async {
            final ok = await showSmashConfirm(
              context: context,
              title: '활동을 삭제할까요?',
              message: '출석 기록도 함께 사라져요.',
              confirmLabel: '삭제',
              destructive: true,
            );
            onChanged(ok ? '삭제를 눌렀어요' : '취소했어요');
          },
        ),
      ),
    ),
    CatalogState(
      '알림 (버튼 하나)',
      (context) => SmashButton(
        label: '알림 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashAlert(context: context, title: '저장했어요', message: '변경한 내용이 반영됐어요.'),
      ),
    ),
    CatalogState(
      '긴 내용 (가운데만 스크롤)',
      (context) => SmashButton(
        label: '긴 대화상자 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashAlert(context: context, title: '이용 안내', message: _longText * 15),
      ),
    ),
    CatalogState(
      '입력창이 있는 대화상자',
      (context) => SmashButton(
        label: '입력 대화상자 열기',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashDialog<void>(
          context: context,
          builder: (dialogContext) => SmashDialog(
            title: '거절 사유',
            content: const SmashTextField(label: '사유', hint: '사유를 적어 주세요'),
            actions: [
              SmashButton(label: '거절하기', variant: SmashButtonVariant.danger, onPressed: () => Navigator.of(dialogContext).pop()),
              SmashButton(label: '취소', variant: SmashButtonVariant.secondary, onPressed: () => Navigator.of(dialogContext).pop()),
            ],
          ),
        ),
      ),
    ),
  ],
);

final snackBarEntry = CatalogEntry(
  name: 'SmashSnackBar',
  description: '스낵바는 showSmashSnackBar 하나로 띄운다. 한 번에 하나만 보이고, 진행 중 안내는 완료나 실패로 바로 교체된다.',
  states: [
    CatalogState(
      '안내',
      (context) => SmashButton(
        label: '안내 스낵바',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSnackBar(context, '조 편성을 불러왔어요'),
      ),
    ),
    CatalogState(
      '완료',
      (context) => SmashButton(
        label: '완료 스낵바',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSnackBar(context, '저장했어요', tone: SmashSnackTone.success),
      ),
    ),
    CatalogState(
      '오류 + 다시 시도 (6초)',
      (context) => SmashButton(
        label: '오류 스낵바',
        variant: SmashButtonVariant.secondary,
        onPressed: () => showSmashSnackBar(
          context,
          '저장하지 못했어요. 인터넷 연결을 확인해 주세요.',
          tone: SmashSnackTone.error,
          actionLabel: '다시 시도',
          onAction: () {},
        ),
      ),
    ),
    CatalogState(
      '진행 중 → 완료로 교체 (2초 뒤)',
      (context) => SmashButton(
        label: '업로드 흉내 내기',
        variant: SmashButtonVariant.secondary,
        onPressed: () {
          final handle = showSmashSnackBar(context, '사진을 올리는 중이에요', tone: SmashSnackTone.progress);
          Future<void>.delayed(const Duration(seconds: 2), () {
            handle.replace('사진을 올렸어요', tone: SmashSnackTone.success);
          });
        },
      ),
    ),
    CatalogState(
      '연달아 띄우기 (쌓이지 않고 마지막 것만)',
      (context) => SmashButton(
        label: '세 번 연달아',
        variant: SmashButtonVariant.secondary,
        onPressed: () {
          showSmashSnackBar(context, '첫 번째');
          showSmashSnackBar(context, '두 번째');
          showSmashSnackBar(context, '세 번째 (이것만 보여야 해요)');
        },
      ),
    ),
  ],
);

final inlineNoticeEntry = CatalogEntry(
  name: 'SmashInlineNotice',
  description: '화면 안에 계속 보이는 안내. 폼 전체 오류, 상태 설명에 쓴다. 입력창 하나의 오류는 입력창의 오류 문구로.',
  states: [
    CatalogState('정보', (_) => const SmashInlineNotice(message: '마감 전에는 언제든 바꿀 수 있어요.')),
    CatalogState('성공', (_) => const SmashInlineNotice(tone: SmashNoticeTone.success, message: '신청을 보냈어요.')),
    CatalogState(
      '주의 + 제목',
      (_) => const SmashInlineNotice(
        tone: SmashNoticeTone.warning,
        title: '마감이 가까워요',
        message: '오늘 밤 11시 59분에 마감돼요.',
      ),
    ),
    CatalogState(
      '오류 + 다시 시도',
      (_) => SmashInlineNotice(
        tone: SmashNoticeTone.danger,
        message: '목록을 불러오지 못했어요. 인터넷 연결을 확인해 주세요.',
        actionLabel: '다시 시도',
        onAction: () {},
      ),
    ),
    CatalogState(
      '긴 글',
      (_) => const SmashInlineNotice(
        tone: SmashNoticeTone.info,
        title: '이월 안내',
        message: _longText,
      ),
    ),
  ],
);
