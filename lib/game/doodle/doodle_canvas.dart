import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'doodle_model.dart';

const _paper = Color(0xFFFFFDF7);

Color _parseInk(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

class DoodleController extends ChangeNotifier {
  final DoodleDrawingState drawing = DoodleDrawingState();

  void setColor(String color) {
    if (!DoodleRules.colors.contains(color)) return;
    drawing.color = color;
    notifyListeners();
  }

  void setWidth(int width) {
    if (!DoodleRules.widths.contains(width)) return;
    drawing.width = width;
    notifyListeners();
  }

  void begin(Offset local, Size size) {
    drawing.start(_relative(local, size));
    notifyListeners();
  }

  void extend(Offset local, Size size) {
    drawing.add(_relative(local, size));
    notifyListeners();
  }

  void end() {
    drawing.finish();
    notifyListeners();
  }

  void undo() {
    drawing.undo();
    notifyListeners();
  }

  void clear() {
    drawing.clear();
    notifyListeners();
  }

  static DoodlePoint _relative(Offset p, Size s) => DoodlePoint(
        (p.dx / s.width).clamp(0.0, 1.0).toDouble(),
        (p.dy / s.height).clamp(0.0, 1.0).toDouble(),
      );
}

/// A portrait-friendly drawing surface; the starter's layer is read-only.
class DoodleCanvas extends StatelessWidget {
  const DoodleCanvas({
    super.key,
    required this.controller,
    this.base = const [],
    this.onPaintingChanged,
  });
  final DoodleController controller;
  final List<DoodleStroke> base;
  final ValueChanged<bool>? onPaintingChanged;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              // Raw pointer events avoid the scroll gesture arena swallowing
              // vertical pen strokes on narrow phones.
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  controller.begin(e.localPosition, size);
                  onPaintingChanged?.call(true);
                },
                onPointerMove: (e) => controller.extend(e.localPosition, size),
                onPointerUp: (_) {
                  controller.end();
                  onPaintingChanged?.call(false);
                },
                onPointerCancel: (_) {
                  controller.end();
                  onPaintingChanged?.call(false);
                },
                child: CustomPaint(
                  painter: DoodlePainter(
                    original: base,
                    additions: controller.drawing.strokes,
                    active: controller.drawing.active,
                    activeColor: controller.drawing.color,
                    activeWidth: controller.drawing.width,
                    repaint: controller,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      );
}

/// Also used by the finished-gallery replay view.
class DoodlePainter extends CustomPainter {
  DoodlePainter({
    required this.original,
    this.additions = const [],
    this.active = const [],
    this.activeColor = '#455A64',
    this.activeWidth = 5,
    this.progress,
    Listenable? repaint,
  }) : super(repaint: repaint ?? progress);

  final List<DoodleStroke> original;
  final List<DoodleStroke> additions;
  final List<DoodlePoint> active;
  final String activeColor;
  final int activeWidth;
  final Animation<double>? progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);
    final grid = Paint()
      ..color = const Color(0xFFF1ECE4)
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final all = [...original, ...additions];
    final total = DoodleRules.pointsIn(all);
    var remaining = progress == null
        ? total
        : (total * progress!.value.clamp(0.0, 1.0)).ceil();
    for (final stroke in all) {
      if (remaining <= 0) break;
      final visible = math.min(remaining, stroke.points.length);
      _drawStroke(canvas, size, stroke.points.take(visible).toList(),
          stroke.color, stroke.width);
      remaining -= visible;
    }
    if (progress == null && active.isNotEmpty) {
      _drawStroke(canvas, size, active, activeColor, activeWidth);
    }
  }

  void _drawStroke(Canvas canvas, Size size, List<DoodlePoint> points,
      String color, int width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = _parseInk(color)
      ..strokeWidth = width.toDouble() * math.min(size.width, size.height) / 320
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    Offset convert(DoodlePoint p) =>
        Offset(p.x * size.width, p.y * size.height);
    if (points.length == 1) {
      canvas.drawCircle(convert(points.first), paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()
      ..moveTo(convert(points.first).dx, convert(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.x * size.width, p.y * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DoodlePainter old) =>
      old.original != original ||
      old.additions != additions ||
      old.active != active ||
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.activeWidth != activeWidth;
}
