import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/game/doodle/doodle_canvas.dart';

void main() {
  testWidgets('a drag creates an editable stroke', (tester) async {
    final controller = DoodleController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: DoodleCanvas(controller: controller),
          ),
        ),
      ),
    ));
    final rect = tester.getRect(find.byType(DoodleCanvas));
    final gesture =
        await tester.startGesture(rect.topLeft + const Offset(40, 60));
    await gesture.moveBy(const Offset(40, 40));
    await gesture.moveBy(const Offset(35, 15));
    await gesture.up();
    await tester.pump();
    expect(controller.drawing.strokes, hasLength(1));
    expect(controller.drawing.strokes.first.points.length,
        greaterThanOrEqualTo(2));
  });
}
