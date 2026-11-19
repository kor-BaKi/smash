import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 의미 트리(스크린리더가 보는 것)를 다루는 도구.
/// 위젯 기준 파인더(`find.bySemanticsLabel`)는 가려진 노드도 찾아 주므로, 가려짐이나 동작 수행을 확인할 때 이것을 쓴다.
/// (`tester.ensureSemantics()`를 먼저 켜야 한다)
SemanticsOwner semanticsOwner(WidgetTester tester) {
  SemanticsOwner? owner;
  tester.binding.rootPipelineOwner.visitChildren((child) {
    owner ??= child.semanticsOwner;
  });
  return owner ?? tester.binding.rootPipelineOwner.semanticsOwner!;
}

SemanticsNode? semanticsNode(
  WidgetTester tester,
  bool Function(SemanticsData data) test,
) {
  SemanticsNode? found;
  void walk(SemanticsNode node) {
    if (found != null) return;
    if (test(node.getSemanticsData())) {
      found = node;
      return;
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(semanticsOwner(tester).rootSemanticsNode!);
  return found;
}

bool hasLabel(WidgetTester tester, Pattern label) =>
    semanticsNode(tester, (d) => label.allMatches(d.label).isNotEmpty) != null;

/// 스크린리더의 탈출 제스처(dismiss)를 [label] 노드에 보낸다
void dismissAction(WidgetTester tester, String label) {
  final node = semanticsNode(tester, (d) => d.label == label);
  expect(node, isNotNull, reason: '$label 노드');
  expect(
    node!.getSemanticsData().hasAction(SemanticsAction.dismiss),
    isTrue,
    reason: '$label 에 dismiss 동작',
  );
  semanticsOwner(tester).performAction(node.id, SemanticsAction.dismiss);
}
