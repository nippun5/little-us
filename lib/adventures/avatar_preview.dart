import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'avatar_model.dart';

/// Lightweight, original pseudo-3D preview: rounded geometry, gradients,
/// shadows and layered accessories. In a later milestone replace only this
/// widget with multi-angle animated sprite assets; keep CoupleAvatar IDs.
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key, required this.avatar});
  final CoupleAvatar avatar;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 3 / 4,
        child: CustomPaint(painter: _AvatarPainter(avatar)),
      );
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.avatar);
  final CoupleAvatar avatar;

  Paint _solid(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _shaded(Rect bounds, Color c) => Paint()
    ..isAntiAlias = true
    ..shader = ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      [Color.lerp(c, Colors.white, .28)!, c, Color.lerp(c, Colors.black, .22)!],
      [0, .5, 1],
    );

  void _oval(Canvas c, Rect rect, Color color) =>
      c.drawOval(rect, _solid(color));

  void _round(Canvas c, Rect rect, double radius, Paint paint) => c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);

  Color get skin => AvatarCatalog.swatches[avatar.skinTone]!;
  Color get hair => AvatarCatalog.swatches[avatar.hairColor]!;
  Color get clothing => switch (avatar.outfit) {
        'hoodie' => const Color(0xFF778CB4),
        'sweater' => const Color(0xFFDE99AC),
        'summer' => const Color(0xFFF3C488),
        'denim' => const Color(0xFF557DA1),
        _ => const Color(0xFF778CB4),
      };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 320);
    if (avatar.bodyStyle == 'petite') {
      canvas.translate(120, 18);
      canvas.scale(.93, .93);
      canvas.translate(-120, 0);
    }

    // Grounding shadow and legs.
    _oval(
        canvas, const Rect.fromLTWH(51, 287, 138, 18), const Color(0x33746A72));
    final pants = avatar.outfit == 'summer'
        ? const Color(0xFFC1A0B9)
        : const Color(0xFF58647D);
    _round(canvas, const Rect.fromLTWH(84, 226, 31, 60), 12,
        _shaded(const Rect.fromLTWH(84, 226, 31, 60), pants));
    _round(canvas, const Rect.fromLTWH(127, 226, 31, 60), 12,
        _shaded(const Rect.fromLTWH(127, 226, 31, 60), pants));
    _round(canvas, const Rect.fromLTWH(74, 279, 46, 21), 11,
        _shaded(const Rect.fromLTWH(74, 279, 46, 21), const Color(0xFFF7F3F1)));
    _round(
        canvas,
        const Rect.fromLTWH(125, 279, 46, 21),
        11,
        _shaded(
            const Rect.fromLTWH(125, 279, 46, 21), const Color(0xFFF7F3F1)));

    // Back hair first: bob / long silhouettes frame the face.
    if (avatar.hairStyle == 'long' || avatar.hairStyle == 'bob') {
      final bottom = avatar.hairStyle == 'long' ? 216.0 : 163.0;
      final back = Path()
        ..moveTo(74, 92)
        ..quadraticBezierTo(58, 121, 69, bottom)
        ..quadraticBezierTo(117, bottom + 12, 172, bottom)
        ..quadraticBezierTo(185, 125, 168, 91)
        ..close();
      canvas.drawPath(back, _shaded(Rect.fromLTRB(64, 80, 180, bottom), hair));
    }

    // Rounded arms behind the top; hands peek out.
    _round(canvas, const Rect.fromLTWH(57, 176, 27, 71), 14,
        _shaded(const Rect.fromLTWH(57, 176, 27, 71), clothing));
    _round(canvas, const Rect.fromLTWH(158, 176, 27, 71), 14,
        _shaded(const Rect.fromLTWH(158, 176, 27, 71), clothing));
    _oval(canvas, const Rect.fromLTWH(58, 234, 25, 28), skin);
    _oval(canvas, const Rect.fromLTWH(159, 234, 25, 28), skin);

    // Body, neck and subtle highlight.
    _round(canvas, const Rect.fromLTWH(74, 168, 94, 83), 27,
        _shaded(const Rect.fromLTWH(74, 168, 94, 83), clothing));
    _round(canvas, const Rect.fromLTWH(109, 157, 24, 30), 10,
        _shaded(const Rect.fromLTWH(109, 157, 24, 30), skin));
    if (avatar.outfit == 'hoodie') {
      final hood = Path()
        ..moveTo(100, 176)
        ..quadraticBezierTo(121, 204, 141, 176);
      canvas.drawPath(
          hood,
          Paint()
            ..color = const Color(0xAAFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(const Offset(113, 192), const Offset(112, 219),
          _solid(const Color(0xDDF5ECEB))..strokeWidth = 2.3);
      canvas.drawLine(const Offset(132, 192), const Offset(131, 219),
          _solid(const Color(0xDDF5ECEB))..strokeWidth = 2.3);
      _round(canvas, const Rect.fromLTWH(103, 220, 38, 18), 8,
          _solid(const Color(0x44FFFFFF)));
    } else if (avatar.outfit == 'denim') {
      canvas.drawLine(const Offset(120, 184), const Offset(120, 249),
          _solid(const Color(0xCCEDF1F9))..strokeWidth = 2);
      for (final dy in [200.0, 213.0, 226.0]) {
        _oval(canvas, Rect.fromCircle(center: Offset(123, dy), radius: 2),
            const Color(0xFFF2D7A0));
      }
    } else if (avatar.outfit == 'sweater') {
      for (final dy in [234.0, 238.0, 242.0]) {
        canvas.drawLine(Offset(84, dy), Offset(158, dy),
            _solid(const Color(0x55FFFFFF))..strokeWidth = 1.4);
      }
    } else {
      _round(canvas, const Rect.fromLTWH(89, 182, 64, 10), 5,
          _solid(const Color(0x66FFFFFF)));
    }

    // Head and ears use radial/linear shading to provide depth.
    _oval(canvas, const Rect.fromLTWH(66, 111, 20, 28), skin);
    _oval(canvas, const Rect.fromLTWH(156, 111, 20, 28), skin);
    canvas.drawOval(
      const Rect.fromLTWH(74, 72, 94, 111),
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          const Offset(105, 106),
          86,
          [
            Color.lerp(skin, Colors.white, .20)!,
            skin,
            Color.lerp(skin, Colors.black, .20)!
          ],
          [0, .66, 1],
        ),
    );

    // Hair silhouettes, side locks and curls.
    final fringe = Path()
      ..moveTo(73, 121)
      ..cubicTo(64, 55, 93, 54, 122, 60)
      ..cubicTo(169, 54, 180, 91, 169, 125)
      ..lineTo(161, 106)
      ..quadraticBezierTo(142, 97, 132, 80)
      ..quadraticBezierTo(120, 108, 95, 103)
      ..quadraticBezierTo(88, 109, 77, 123)
      ..close();
    canvas.drawPath(
        fringe, _shaded(const Rect.fromLTWH(70, 58, 106, 70), hair));
    if (avatar.hairStyle == 'curly') {
      for (final pt in [
        const Offset(78, 100),
        const Offset(91, 77),
        const Offset(113, 69),
        const Offset(140, 75),
        const Offset(163, 96),
        const Offset(166, 118),
      ]) {
        canvas.drawCircle(
            pt, 17, _shaded(Rect.fromCircle(center: pt, radius: 17), hair));
      }
    } else if (avatar.hairStyle == 'short') {
      final lock = Path()
        ..moveTo(93, 84)
        ..quadraticBezierTo(104, 101, 114, 93)
        ..quadraticBezierTo(123, 107, 139, 90)
        ..quadraticBezierTo(123, 82, 93, 84);
      canvas.drawPath(lock, _solid(hair));
    } else {
      _round(canvas, const Rect.fromLTWH(75, 109, 10, 54), 5,
          _shaded(const Rect.fromLTWH(75, 109, 10, 54), hair));
      _round(canvas, const Rect.fromLTWH(157, 105, 10, 59), 5,
          _shaded(const Rect.fromLTWH(157, 105, 10, 59), hair));
    }

    // Eyes, highlights, gentle cheek blush and smile.
    final dark = const Color(0xFF302935);
    for (final x in [101.0, 141.0]) {
      _oval(canvas, Rect.fromLTWH(x - 5, 125, 9, 12), dark);
      _oval(canvas, Rect.fromLTWH(x - 3, 126, 3, 4), Colors.white);
    }
    _oval(canvas, const Rect.fromLTWH(83, 144, 14, 7), const Color(0x44D56A7B));
    _oval(
        canvas, const Rect.fromLTWH(146, 144, 14, 7), const Color(0x44D56A7B));
    canvas.drawArc(
        const Rect.fromLTWH(111, 143, 22, 14),
        0.1,
        2.8,
        false,
        _solid(const Color(0xFF8F5C57))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1
          ..strokeCap = StrokeCap.round);

    // Accessories layer on top.
    if (avatar.accessory == 'glasses') {
      final stroke = _solid(const Color(0xFF493E49))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(85, 120, 32, 24), const Radius.circular(9)),
          stroke);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(125, 120, 32, 24), const Radius.circular(9)),
          stroke);
      canvas.drawLine(const Offset(117, 128), const Offset(125, 128), stroke);
    } else if (avatar.accessory == 'cap') {
      final capColor = const Color(0xFFABC7BA);
      _oval(canvas, const Rect.fromLTWH(78, 59, 84, 43), capColor);
      _round(canvas, const Rect.fromLTWH(101, 90, 82, 12), 6,
          _shaded(const Rect.fromLTWH(101, 90, 82, 12), capColor));
    } else if (avatar.accessory == 'bow') {
      final bowColor = const Color(0xFFDE879A);
      final left = Path()
        ..moveTo(154, 79)
        ..lineTo(132, 67)
        ..lineTo(133, 89)
        ..close();
      final right = Path()
        ..moveTo(154, 79)
        ..lineTo(175, 62)
        ..lineTo(177, 94)
        ..close();
      canvas.drawPath(
          left, _shaded(const Rect.fromLTWH(132, 67, 22, 22), bowColor));
      canvas.drawPath(
          right, _shaded(const Rect.fromLTWH(154, 62, 23, 32), bowColor));
      _oval(canvas, const Rect.fromLTWH(149, 74, 12, 12), bowColor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.avatar != avatar;
}
