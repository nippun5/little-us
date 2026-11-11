import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/game/doodle/doodle_model.dart';

void main() {
  const first = DoodleStroke(
    color: '#455A64',
    width: 5,
    points: [DoodlePoint(.15, .25), DoodlePoint(.75, .8)],
  );

  test('stroke encoding round-trips normalized geometry', () {
    final decoded = DoodleRules.decode(DoodleRules.encode([first]));
    expect(decoded, hasLength(1));
    expect(decoded.first.color, first.color);
    expect(decoded.first.width, 5);
    expect(decoded.first.points[1].x, closeTo(.75, .001));
    expect(DoodleRules.validate(decoded), isNull);
  });

  test('empty, wrong color and out-of-bounds strokes are rejected', () {
    expect(DoodleRules.validate([]), isNotNull);
    expect(
        DoodleRules.validate([
          const DoodleStroke(color: '#123456', width: 5, points: [
            DoodlePoint(.1, .1),
            DoodlePoint(.2, .2),
          ]),
        ]),
        isNotNull);
    expect(
        DoodleRules.validate([
          const DoodleStroke(color: '#455A64', width: 5, points: [
            DoodlePoint(.1, .1),
            DoodlePoint(1.2, .2),
          ]),
        ]),
        isNotNull);
  });

  test('drawing state supports undo and clear', () {
    final drawing = DoodleDrawingState();
    drawing.start(const DoodlePoint(.2, .2));
    drawing.add(const DoodlePoint(.4, .4));
    drawing.finish();
    expect(drawing.strokes, hasLength(1));
    drawing.undo();
    expect(drawing.strokes, isEmpty);
    drawing.start(const DoodlePoint(.2, .2));
    drawing.finish();
    expect(drawing.strokes.first.points.length, 2);
    drawing.clear();
    expect(drawing.pointCount, 0);
  });

  test('partner may finish only unfinished drawing they did not start', () {
    final entry = CoupleDoodle.fromJson({
      'id': 'test',
      'prompt': DoodleRules.prompts.first,
      'starter_name': 'Alex',
      'is_mine': false,
      'is_finished': false,
      'created_at': DateTime.utc(2026, 11, 11).toIso8601String(),
      'starter_strokes': DoodleRules.encode([first]),
      'finish_strokes': [],
    });
    expect(entry.canFinish, true);
  });
}
