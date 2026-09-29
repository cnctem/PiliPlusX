import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('opens with material_ui localizations and returns selection', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<int>(
                  context: context,
                  builder: (context) => SelectDialog<int>(
                    title: '选择点赞率（0即不过滤）',
                    value: 0,
                    values: const [(0, '0 %'), (1, '1 %'), (-1, '自定义')],
                  ),
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    // 回归：曾因 AlertDialog 来自 flutter/material 而在 material_ui
    // 环境下抛 “No MaterialLocalizations found.”，此处必须无异常。
    expect(tester.takeException(), isNull);
    expect(find.text('选择点赞率（0即不过滤）'), findsOneWidget);
    expect(find.text('1 %'), findsOneWidget);

    await tester.tap(find.text('1 %'));
    await tester.pumpAndSettle();

    expect(result, 1);
  });
}
