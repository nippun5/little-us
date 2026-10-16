// Actual Flutter raster captures, with bundled production fonts.
// flutter test tool/capture_test.dart --update-goldens
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/main.dart';
import 'package:little_us/store.dart';

void main() {
  testWidgets('capture phone screenshots', (tester) async {
    tester.view.physicalSize = const Size(432, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final family in ['Nunito', 'Lora']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/$family.ttf'))
        ..addFont(
          rootBundle.load(
            'assets/$family-${family == 'Nunito' ? 'Bold' : 'SemiBold'}.ttf',
          ),
        );
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    await store.startDemo();
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: LittleUs(store: store),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String file) async {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('store/$file').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('screenshot-01-home.png');
    await tester.tap(find.text('Play').last);
    await tester.pumpAndSettle();
    await capture('screenshot-02-play.png');
    await tester.tap(find.text('Notes').last);
    await tester.pumpAndSettle();
    await capture('screenshot-03-notes.png');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
