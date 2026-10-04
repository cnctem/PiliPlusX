import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';

import 'package:PiliPlus/pages/setting/widgets/cdn_select_dialog.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'piliplus-cdn-dialog-test-',
    );
    Hive.init(tempDir.path);
    GStorage.setting = await Hive.openBox('setting');
    GStorage.localCache = await Hive.openBox('localCache');
    await GStorage.setting.put(SettingBoxKey.cdnSpeedTest, false);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('opens CDN dialog with material_ui localizations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('zh', 'CN')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<CdnSelectResult>(
              context: context,
              builder: (_) => const CdnSelectDialog(),
            ),
            child: const Text('打开 CDN 设置'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开 CDN 设置'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CDN 设置'), findsOneWidget);
  });
}
