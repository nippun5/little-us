import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'garage_catalog.dart';

/// Cozy stylized modern luxury sedan; original silhouette, not a licensed car logo.
class GarageScene extends StatelessWidget {
  const GarageScene({super.key, required this.equipped});

  final Map<String, String> equipped;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Our luxury sedan in the shared garage',
        image: true,
        child: AspectRatio(
          aspectRatio: 1.35,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CustomPaint(painter: GaragePainter(equipped)),
          ),
        ),
      );
}

class GaragePainter extends CustomPainter {
  GaragePainter(this.equipped);
  final Map<String, String> equipped;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 440, size.height / 320);
    final paintColor = garagePaintColor(equipped['paint'] ?? 'paint_silver');
    const charcoal = Color(0xFF303544);
    const chrome = Color(0xFFDCE7EF);
    const cream = Color(0xFFFFF7EF);
    const outline = Color(0xFF485062);

    void shape(Path path, Color color,
        {Color? stroke, double strokeWidth = 1.7}) {
      canvas.drawPath(path, Paint()..color = color);
      if (stroke != null) {
        canvas.drawPath(
            path,
            Paint()
              ..color = stroke
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round);
      }
    }

    void rect(double x, double y, double w, double h, Color color,
        [double r = 0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        Paint()..color = color,
      );
    }

    void ellipse(double x, double y, double w, double h, Color color) {
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    }

    void line(double x1, double y1, double x2, double y2, Color color,
        [double width = 2]) {
      canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round);
    }

    // Garage: soft segmented door, side walls, lighting and floor.
    rect(0, 0, 440, 320, const Color(0xFFF2DFDC));
    rect(30, 32, 380, 208, const Color(0xFFD9C7CE), 11);
    rect(39, 42, 362, 193, const Color(0xFFF9EDE8), 8);
    for (var y = 82.0; y < 236; y += 38) {
      line(40, y, 400, y, const Color(0xFFE2D0CB), 2.7);
    }
    rect(0, 236, 440, 84, const Color(0xFFD8C2B9));
    for (var x = -90.0; x < 530; x += 75) {
      line(x, 320, x + 50, 236, const Color(0x33FFFFFF));
    }
    rect(0, 236, 440, 6, const Color(0xFFB69A95));
    rect(47, 17, 346, 9, const Color(0xFFC8ADB3), 4);
    rect(177, 18, 86, 12, const Color(0xFFFFE8B5), 5);
    rect(16, 165, 20, 72, const Color(0xFFB9A2A7), 5);
    rect(405, 160, 18, 77, const Color(0xFFB9A2A7), 5);
    ellipse(42, 252, 369, 37, const Color(0x506E5961));

    // Long low hood + streamlined roofline, inspired by current luxury sedans.
    final roof = Path()
      ..moveTo(105, 193)
      ..lineTo(150, 157)
      ..quadraticBezierTo(164, 146, 190, 145)
      ..lineTo(262, 145)
      ..quadraticBezierTo(287, 145, 303, 164)
      ..lineTo(325, 193)
      ..close();
    shape(roof, paintColor, stroke: outline, strokeWidth: 2.6);

    if (equipped['roof'] == 'roof_panorama') {
      shape(
          Path()
            ..moveTo(180, 151)
            ..lineTo(257, 151)
            ..quadraticBezierTo(271, 151, 282, 160)
            ..lineTo(169, 160)
            ..close(),
          const Color(0xFF273C54));
      line(182, 153, 245, 153, const Color(0xFF7F9FAE), 2);
    }

    // Four window panes; the front windshield has its own upgrade.
    final glass = equipped['windows'] == 'windows_tinted'
        ? const Color(0xFF2E425D)
        : const Color(0xFFB5D8E4);
    shape(
        Path()
          ..moveTo(152, 190)
          ..lineTo(175, 157)
          ..lineTo(214, 157)
          ..lineTo(214, 191)
          ..close(),
        glass,
        stroke: chrome);
    shape(
        Path()
          ..moveTo(219, 157)
          ..lineTo(257, 157)
          ..quadraticBezierTo(275, 157, 285, 175)
          ..lineTo(295, 191)
          ..lineTo(219, 191)
          ..close(),
        glass,
        stroke: chrome);
    line(178, 163, 202, 163, const Color(0x88FFFFFF), 3);

    // Raked front windshield, including optional sun-shade strip.
    final windshield = Path()
      ..moveTo(295, 163)
      ..lineTo(310, 185)
      ..lineTo(326, 196)
      ..lineTo(300, 195)
      ..lineTo(282, 170)
      ..close();
    shape(windshield, const Color(0xFF8AB0C7), stroke: chrome);
    if (equipped['windshield'] == 'windshield_sunstrip') {
      shape(
          Path()
            ..moveTo(295, 163)
            ..lineTo(310, 185)
            ..lineTo(316, 190)
            ..lineTo(286, 174)
            ..close(),
          const Color(0xFF243955));
    }

    // Shoulder line, curved trunk and premium long hood.
    final body = Path()
      ..moveTo(29, 220)
      ..quadraticBezierTo(30, 207, 56, 203)
      ..lineTo(111, 194)
      ..lineTo(315, 193)
      ..lineTo(373, 196)
      ..quadraticBezierTo(402, 197, 416, 211)
      ..lineTo(426, 225)
      ..lineTo(426, 249)
      ..quadraticBezierTo(423, 258, 407, 258)
      ..lineTo(49, 258)
      ..quadraticBezierTo(24, 257, 27, 242)
      ..close();
    shape(body, paintColor, stroke: outline, strokeWidth: 2.7);
    shape(
        Path()
          ..moveTo(43, 214)
          ..quadraticBezierTo(199, 200, 364, 207)
          ..lineTo(380, 211)
          ..quadraticBezierTo(183, 210, 48, 224)
          ..close(),
        Colors.white.withValues(alpha: .22));
    line(111, 213, 327, 213, chrome.withValues(alpha: .85), 2.4);
    line(150, 216, 145, 253, outline.withValues(alpha: .55), 1.3);
    line(271, 214, 274, 253, outline.withValues(alpha: .55), 1.3);
    rect(201, 218, 20, 4, chrome, 2);
    rect(282, 218, 19, 4, chrome, 2);

    // Black or chrome side mirror.
    shape(
        Path()
          ..moveTo(296, 186)
          ..quadraticBezierTo(309, 182, 316, 192)
          ..lineTo(312, 199)
          ..lineTo(297, 199)
          ..close(),
        equipped['mirrors'] == 'mirrors_black' ? charcoal : chrome,
        stroke: outline);

    // Wheel arch trim and optionally flared fenders.
    for (final wheelX in [113.0, 347.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(wheelX, 253), radius: 39),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = equipped['fenders'] == 'fenders_flared' ? 10 : 5,
      );
      ellipse(wheelX - 31, 228, 62, 62, const Color(0xFF252631));
      ellipse(
          wheelX - 23,
          236,
          46,
          46,
          equipped['wheels'] == 'wheels_sport'
              ? const Color(0xFF505A69)
              : chrome);
      ellipse(wheelX - 17, 242, 34, 34, const Color(0xFF88929D));
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5;
        line(
            wheelX + 3 * math.cos(angle),
            259 + 3 * math.sin(angle),
            wheelX + 16 * math.cos(angle),
            259 + 16 * math.sin(angle),
            equipped['wheels'] == 'wheels_sport' ? charcoal : cream,
            equipped['wheels'] == 'wheels_sport' ? 4 : 6);
      }
      ellipse(wheelX - 5, 254, 10, 10, chrome);
    }

    // Luxury sedan grille is deliberately visible in the 3/4 side illustration.
    final grille = Path()
      ..moveTo(383, 212)
      ..lineTo(417, 217)
      ..lineTo(417, 244)
      ..lineTo(381, 242)
      ..close();
    shape(grille, const Color(0xFF283441), stroke: chrome, strokeWidth: 2.7);
    if (equipped['grille'] == 'grille_diamond') {
      for (var x = 386.0; x <= 414; x += 7) {
        for (var y = 219.0; y <= 240; y += 7) {
          ellipse(x, y, 2.9, 2.9, chrome);
        }
      }
    } else {
      for (var y = 219.0; y <= 239; y += 6) {
        line(386, y, 414, y + 1, chrome, 1.7);
      }
    }
    // Generic oval emblem, intentionally no manufacturer's trademark.
    ellipse(392, 222, 15, 9, chrome);
    ellipse(396, 224, 7, 5, const Color(0xFF647585));

    // Separate warm/LED headlight treatments.
    final headlight = equipped['headlights'] == 'headlights_led'
        ? const Color(0xFFEAFBFF)
        : const Color(0xFFFFDEA0);
    shape(
        Path()
          ..moveTo(355, 199)
          ..lineTo(384, 200)
          ..lineTo(379, 211)
          ..lineTo(357, 209)
          ..close(),
        headlight,
        stroke: chrome);
    if (equipped['headlights'] == 'headlights_led') {
      line(358, 206, 377, 206, const Color(0xFF7CCEE7), 2.8);
      line(377, 206, 381, 202, const Color(0xFF7CCEE7), 2.5);
    }

    // Front bumper/lower vents; sport option adds splitter.
    if (equipped['bumper'] == 'bumper_sport') {
      rect(380, 246, 44, 6, charcoal, 3);
      rect(375, 251, 53, 5, chrome, 2);
      shape(
          Path()
            ..moveTo(404, 229)
            ..lineTo(420, 232)
            ..lineTo(420, 242)
            ..lineTo(402, 240)
            ..close(),
          charcoal);
    } else {
      line(385, 249, 423, 249, chrome, 3);
    }

    // Tiny heart decoration keeps the shared-game atmosphere.
    shape(
        Path()
          ..moveTo(38, 65)
          ..cubicTo(17, 48, 16, 80, 38, 88)
          ..cubicTo(60, 80, 59, 48, 38, 65),
        const Color(0xFFD895A2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GaragePainter oldDelegate) {
    if (oldDelegate.equipped.length != equipped.length) return true;
    for (final entry in equipped.entries) {
      if (oldDelegate.equipped[entry.key] != entry.value) return true;
    }
    return false;
  }
}
