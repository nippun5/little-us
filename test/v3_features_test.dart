import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:little_us/store.dart';
import 'package:little_us/v3_features.dart';
import 'package:little_us/room_scenes.dart';
import 'package:little_us/photo_processor.dart';
import 'v2_store_test.dart' show FakeFridge;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = AppStore(
      await SharedPreferences.getInstance(),
      fridgeBridge: FakeFridge(),
    );
    await s.startDemo();
  });
  tearDown(() => s.dispose());
  test('accessories charge once, persist, and can be removed freely', () async {
    await s.adoptPet('cat', 'Mochi');
    await s.equipAccessory('collar');
    await s.equipAccessory('collar');
    expect(s.coins, 90);
    expect(s.ownedAccessories, ['collar']);
    await s.equipAccessory('none');
    expect(s.coins, 90);
    await s.startDemo();
    expect(s.petAccessory, 'none');
    await s.equipAccessory('collar');
    expect(s.coins, 90);
    await s.equipAccessory('crown');
    expect(s.coins, 0);
    await expectLater(s.equipAccessory('bow'), throwsA(isA<Exception>()));
    expect(s.petAccessory, 'crown');
  });
  test(
    'photos stay in own slot, scope is checked, and sign-out clears bytes',
    () async {
      await s.unlockRoom('bedroom');
      final bytes = Uint8List.fromList([255, 216, 255, 217]);
      await s.uploadFrame(bytes, 'demo');
      expect(s.frameBytes.keys, ['demo-a']);
      await expectLater(
        s.uploadFrame(bytes, 'other-home'),
        throwsA(isA<Exception>()),
      );
      await s.removeMyFrame();
      expect(s.frameBytes, isEmpty);
      await s.uploadFrame(bytes, 'demo');
      await s.signOut();
      expect(s.frameBytes, isEmpty);
    },
  );
  test('processor creates bounded JPEG from PNG pixels', () async {
    final source = img.Image(width: 1600, height: 800);
    img.fill(source, color: img.ColorRgb8(200, 100, 120));
    final result = await prepareFramePhoto(
      Uint8List.fromList(img.encodePng(source)),
    );
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, 1024);
    expect(decoded.height, 512);
    expect(result.length, lessThanOrEqualTo(1048576));
    expect(decoded.exif.isEmpty, isTrue);
  });
  test('photo processing strips existing camera and GPS metadata', () async {
    final original = img.Image(width: 32, height: 24);
    original.exif.imageIfd[0x010f] = img.IfdValueAscii('Private camera');
    original.exif.gpsIfd[1] = img.IfdValueAscii('N');
    final encoded = Uint8List.fromList(img.encodeJpg(original));
    expect(img.decodeJpg(encoded)!.exif.isEmpty, isFalse);
    final safe = await prepareFramePhoto(encoded);
    expect(img.decodeJpg(safe)!.exif.isEmpty, isTrue);
  });
  testWidgets('two frames and accessories fit narrow screens', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await s.unlockRoom('bedroom');
    await s.adoptPet('cat', 'Mochi');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                RoomScene(
                  room: 'bedroom',
                  theme: 'peach',
                  petKind: 'cat',
                  accessory: 'bow',
                  bedroomFrames: BedroomWallFrames(store: s),
                ),
                BedroomPhotoPanel(store: s),
                PetAccessoriesPanel(store: s),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your frame'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('bedroom-frame-a'))).height,
      greaterThan(50),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('bedroom-frame-b'))).height,
      greaterThan(50),
    );
    expect(find.text('Your partner’s frame'), findsOneWidget);
    expect(find.text('Choose my photo'), findsOneWidget);
    expect(find.text('A tiny wardrobe'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
