import 'package:PiliPlus/models/common/media_control_button.dart';
import 'package:PiliPlus/pages/setting/widgets/media_control_order_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('keeps playPause selected and returns selected controls', (
    tester,
  ) async {
    List<MediaControlButton>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<List<MediaControlButton>>(
                  context: context,
                  builder: (context) => const MediaControlOrderDialog(
                    selectedValues: [
                      MediaControlButton.playPause,
                      MediaControlButton.next,
                    ],
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
    expect(find.text('系统媒体控制按钮'), findsOneWidget);
    expect(find.text('上一集'), findsOneWidget);

    final playPauseTile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('播放/暂停'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(playPauseTile.value, isTrue);
    await tester.tap(find.text('播放/暂停'));
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('播放/暂停'),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.text('上一集'));
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, [
      MediaControlButton.playPause,
      MediaControlButton.next,
      MediaControlButton.previous,
    ]);
  });
}
