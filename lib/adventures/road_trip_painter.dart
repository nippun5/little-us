import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../garage_catalog.dart';
import 'road_trip_timeline.dart';

/// The existing 8-second road-trip animation, now filmed from a slightly
/// elevated chase camera behind the couple's car.
///
/// Drop-in replacement for the Milestone 3B road_trip_painter.dart.
/// No new dependencies, assets, database changes, or navigation changes.
class RoadTripPainter extends CustomPainter {
  RoadTripPainter({required this.animation, required this.equipped})
      : super(repaint: animation);

  final Animation<double> animation;
  final Map<String, String> equipped;

  static Paint _paint(Color color) => Paint()..color = color;

  static Color _blend(Color a, Color b, double amount) =>
      Color.lerp(a, b, amount.clamp(0.0, 1.0).toDouble())!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final progress = animation.value.clamp(0.0, 1.0).toDouble();
    final coast = RoadTripTimeline.coastBlend(progress);
    final horizon = h * .435;
    final roadHeight = h - horizon;
    final travel = progress * 8.2;

    // The centerline bends most at the horizon and returns to camera-center
    // near the foreground. This is a believable (but gentle) S-curve.
    double center(double z) {
      final bend = math.sin(progress * math.pi * 2 * 1.25 + .6);
      final distant = math.pow(1.0 - z, 1.65).toDouble();
      final secondBend = math.sin(progress * math.pi * 3.1 + z * 2.4);
      return w * (.5 + .115 * bend * distant + .018 * secondBend * distant);
    }

    double halfRoad(double z) =>
        w * (.052 + .57 * math.pow(z, 1.28).toDouble());

    double roadY(double z) => horizon + roadHeight * z;

    // --- Sky, sunlight, distant landscape, and coastline. ---
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _blend(const Color(0xFF4E8FAF), const Color(0xFFDA8196), coast),
            _blend(const Color(0xFFA9D3D9), const Color(0xFFF4B99B), coast),
            _blend(const Color(0xFFE4E9CF), const Color(0xFFF5DEB1), coast),
          ],
        ).createShader(Offset.zero & size),
    );

    // Soft solar glow is intentionally subtle, not a flashlight effect.
    final sun = Offset(w * (.79 - .07 * coast), h * .20);
    final sunRadius = math.min(w, h) * .075;
    canvas.drawCircle(sun, sunRadius * 1.9,
        _paint(const Color(0x66FFF1CE).withValues(alpha: .14 + coast * .08)));
    canvas.drawCircle(
        sun,
        sunRadius,
        _paint(
            _blend(const Color(0xFFFFF0C8), const Color(0xFFFFCC87), coast)));

    final mountain = Path()
      ..moveTo(0, horizon)
      ..lineTo(0, h * .33)
      ..quadraticBezierTo(w * .22, h * .26, w * .46, h * .41)
      ..quadraticBezierTo(w * .76, h * .31, w, h * .38)
      ..lineTo(w, horizon)
      ..close();
    canvas.drawPath(
        mountain,
        _paint(
            _blend(const Color(0xFF678E7C), const Color(0xFF9DA7A5), coast)));
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      _paint(_blend(const Color(0xFF6F8E65), const Color(0xFFD8B891), coast)),
    );

    // Ocean to the right of the coastal highway.
    if (coast > 0) {
      canvas.drawRect(
        Rect.fromLTRB(w * .69, horizon, w, h * .70),
        _paint(const Color(0xFF62A5B5).withValues(alpha: coast)),
      );
      for (var i = 0; i < 7; i++) {
        final yy = horizon + h * (.016 + i * .028);
        canvas.drawLine(
          Offset(w * .72, yy),
          Offset(w, yy + 2),
          Paint()
            ..color = Colors.white.withValues(alpha: coast * .3)
            ..strokeWidth = 1.6,
        );
      }
    }

    // --- Shoulder and asphalt follow the same perspective curve. ---
    Path roadRibbon(double extra) {
      final path = Path();
      const samples = 36;
      for (var i = 0; i <= samples; i++) {
        final z = i / samples;
        final point = Offset(
          center(z) - halfRoad(z) - extra * (1 + 2.5 * z),
          roadY(z),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      for (var i = samples; i >= 0; i--) {
        final z = i / samples;
        path.lineTo(
          center(z) + halfRoad(z) + extra * (1 + 2.5 * z),
          roadY(z),
        );
      }
      return path..close();
    }

    canvas.drawPath(
        roadRibbon(5.0),
        _paint(
            _blend(const Color(0xFFB4A58F), const Color(0xFFC4A897), coast)));
    canvas.drawPath(
        roadRibbon(0),
        _paint(
            _blend(const Color(0xFF545C66), const Color(0xFF65616A), coast)));

    Path edgeLine(double side) {
      final line = Path();
      const samples = 36;
      for (var i = 0; i <= samples; i++) {
        final z = i / samples;
        final x = center(z) + side * (halfRoad(z) - 4 * (1 + z));
        if (i == 0) {
          line.moveTo(x, roadY(z));
        } else {
          line.lineTo(x, roadY(z));
        }
      }
      return line;
    }

    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        edgeLine(side),
        Paint()
          ..color = const Color(0xFFEEDFC3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }

    // Animated center-lane dashes get longer and wider near the camera.
    for (var i = 0; i < 15; i++) {
      final u = (i / 15 + travel) % 1.0;
      final z = math.pow(u, 1.85).toDouble();
      final far = (z + .014 + .053 * z).clamp(0.0, 1.0).toDouble();
      final nearWidth = 1.0 + 5.5 * z;
      final farWidth = 1.0 + 5.5 * far;
      final dash = Path()
        ..moveTo(center(z) - nearWidth, roadY(z))
        ..lineTo(center(z) + nearWidth, roadY(z))
        ..lineTo(center(far) + farWidth, roadY(far))
        ..lineTo(center(far) - farWidth, roadY(far))
        ..close();
      canvas.drawPath(dash, _paint(const Color(0xFFF7EACD)));
    }

    // Near trees grow bigger and move faster (parallax). They match the curved
    // road boundary; the camera stays behind the car instead of side-on.
    for (var i = 0; i < 14; i++) {
      final u = (i / 14 + travel * .49) % 1.0;
      final z = math.pow(u, 1.72).toDouble();
      final y = roadY(z);
      final r = 5.0 + 46.0 * z;
      for (final side in [-1.0, 1.0]) {
        final x = center(z) + side * (halfRoad(z) + r * 1.4);
        if (coast < 1) _pine(canvas, x, y, r, 1 - coast);
        if (coast > 0 && i.isEven) {
          _palm(canvas, x, y, r * 1.12, coast);
        }
      }
    }

    // --- Rear chase-camera vehicle. It stays near the bottom of the frame. ---
    final carWidth = math.min(w * .72, h * .50);
    final carHeight = carWidth * .65;
    final sway = math.sin(progress * math.pi * 2 * 1.25 + .6);
    final bob = math.sin(progress * math.pi * 2 * 17) * 1.25;
    final carCenter = Offset(w * .5 - sway * w * .006, h * .775 + bob);
    canvas.save();
    canvas.translate(carCenter.dx, carCenter.dy - carHeight / 2);
    canvas.rotate(sway * .009);
    canvas.translate(-carWidth / 2, -carHeight / 2);
    _rearCar(canvas, Size(carWidth, carHeight), equipped);
    canvas.restore();

    // Existing arrival fade and timeline remain unchanged.
    if (progress > .90) {
      final fade = ((progress - .90) / .10).clamp(0.0, 1.0).toDouble();
      canvas.drawRect(
        Offset.zero & size,
        _paint(const Color(0xFFFFF2DA).withValues(alpha: fade * .72)),
      );
    }
  }

  void _pine(Canvas canvas, double x, double y, double r, double opacity) {
    canvas.drawRect(
      Rect.fromLTWH(x - r * .10, y - r, r * .20, r * 1.1),
      _paint(const Color(0xFF53483D).withValues(alpha: opacity)),
    );
    for (var i = 0; i < 3; i++) {
      final top = y - r * (.6 + i * .48);
      final width = r * (1.05 - i * .2);
      final triangle = Path()
        ..moveTo(x, top - r * .95)
        ..lineTo(x - width, top + r * .30)
        ..lineTo(x + width, top + r * .30)
        ..close();
      canvas.drawPath(
        triangle,
        _paint((i.isEven ? const Color(0xFF356A51) : const Color(0xFF3F6D56))
            .withValues(alpha: opacity)),
      );
    }
  }

  void _palm(Canvas canvas, double x, double y, double r, double opacity) {
    final top = Offset(x + r * .19, y - r * 1.6);
    canvas.drawLine(
      Offset(x, y),
      top,
      Paint()
        ..color = const Color(0xFF906E58).withValues(alpha: opacity)
        ..strokeWidth = math.max(2.0, r * .17)
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 6; i++) {
      final angle = math.pi * (i / 5) + .06;
      canvas.drawLine(
        top,
        top +
            Offset(
              math.cos(angle) * r,
              math.sin(angle) * r * .55 - r * .14,
            ),
        Paint()
          ..color = const Color(0xFF468779).withValues(alpha: opacity)
          ..strokeWidth = math.max(2.0, r * .20)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _rearCar(
    Canvas canvas,
    Size size,
    Map<String, String> selection,
  ) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 260);

    final body = garagePaintColor(selection['paint'] ?? 'paint_silver');
    final bodyLight = _blend(body, Colors.white, .28);
    final bodyShadow = _blend(body, Colors.black, .31);
    final glass = selection['windows'] == 'windows_tinted'
        ? const Color(0xFF23374B)
        : const Color(0xFF82B0C2);
    final sport = selection['bumper'] == 'bumper_sport';
    final sportWheels = selection['wheels'] == 'wheels_sport';
    final flared = selection['fenders'] == 'fenders_flared';
    final blackMirrors = selection['mirrors'] == 'mirrors_black';
    final panoramic = selection['roof'] == 'roof_panorama';
    const chrome = Color(0xFFDAE3E8);

    // Ground shadow + two rear tires (rear camera shows tire edges, not faces).
    canvas.drawOval(
        const Rect.fromLTWH(45, 223, 310, 27), _paint(const Color(0x660D1420)));
    for (final tireLeft in [67.0, 302.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tireLeft, 183, 31, 61),
          const Radius.circular(10),
        ),
        _paint(const Color(0xFF22262E)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tireLeft + 5, 200, 21, 34),
          const Radius.circular(5),
        ),
        _paint(sportWheels ? const Color(0xFF455263) : const Color(0xFFB9C6CF)),
      );
    }

    // Rear-view mirrors protrude slightly beyond the cabin.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(74, 105, 29, 18), const Radius.circular(7)),
      _paint(blackMirrors ? const Color(0xFF292E38) : bodyLight),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(297, 105, 29, 18), const Radius.circular(7)),
      _paint(blackMirrors ? const Color(0xFF292E38) : bodyLight),
    );

    // Roof and rear C-pillars; seen from above and behind.
    final roof = Path()
      ..moveTo(99, 149)
      ..lineTo(122, 85)
      ..quadraticBezierTo(130, 49, 158, 45)
      ..lineTo(242, 45)
      ..quadraticBezierTo(270, 49, 278, 85)
      ..lineTo(301, 149)
      ..close();
    canvas.drawPath(roof, _paint(bodyShadow));
    final roofHighlight = Path()
      ..moveTo(134, 84)
      ..quadraticBezierTo(144, 52, 164, 52)
      ..lineTo(235, 52)
      ..quadraticBezierTo(256, 54, 267, 84)
      ..close();
    canvas.drawPath(roofHighlight, _paint(bodyLight));
    if (panoramic) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(161, 54, 78, 23),
          const Radius.circular(8),
        ),
        _paint(const Color(0xFF243B50)),
      );
      canvas.drawLine(
        const Offset(172, 59),
        const Offset(228, 59),
        Paint()
          ..color = Colors.white.withValues(alpha: .20)
          ..strokeWidth = 2,
      );
    }

    final rearGlass = Path()
      ..moveTo(139, 87)
      ..quadraticBezierTo(146, 68, 162, 66)
      ..lineTo(238, 66)
      ..quadraticBezierTo(253, 68, 261, 87)
      ..lineTo(281, 137)
      ..quadraticBezierTo(200, 129, 119, 137)
      ..close();
    canvas.drawPath(rearGlass, _paint(glass));
    canvas.drawPath(
      rearGlass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF263648),
    );
    // Natural sky reflection on the window.
    final reflection = Path()
      ..moveTo(149, 88)
      ..lineTo(174, 77)
      ..lineTo(230, 77)
      ..lineTo(253, 108)
      ..lineTo(152, 108)
      ..close();
    canvas.drawPath(reflection, _paint(Colors.white.withValues(alpha: .10)));
    // Rear-window defogger lines (visible on clear or tinted glass).
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(133 - 2.0 * i, 110 + 7.5 * i),
        Offset(267 + 2.0 * i, 110 + 7.5 * i),
        Paint()
          ..color = const Color(0xFFE4E9E6).withValues(alpha: .15)
          ..strokeWidth = 1,
      );
    }

    // Rounded sculpted rear body and trunk, wider than the cabin.
    final rearBody = Path()
      ..moveTo(93, 132)
      ..quadraticBezierTo(80, 126, 65, 141)
      ..quadraticBezierTo(50, 160, 54, 199)
      ..lineTo(63, 219)
      ..quadraticBezierTo(200, 241, 337, 219)
      ..lineTo(346, 199)
      ..quadraticBezierTo(350, 160, 335, 141)
      ..quadraticBezierTo(320, 126, 307, 132)
      ..quadraticBezierTo(200, 144, 93, 132)
      ..close();
    canvas.drawPath(rearBody, _paint(body));
    canvas.drawPath(
      rearBody,
      Paint()
        ..color = bodyShadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Trunk lid / shoulders: painted reflections that read as 3D volume.
    canvas.drawPath(
      Path()
        ..moveTo(91, 144)
        ..quadraticBezierTo(200, 155, 309, 144)
        ..lineTo(319, 165)
        ..quadraticBezierTo(200, 180, 81, 165)
        ..close(),
      _paint(bodyLight.withValues(alpha: .40)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(62, 201)
        ..quadraticBezierTo(200, 211, 338, 201),
      Paint()
        ..color = bodyShadow.withValues(alpha: .65)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );

    // Wider fender trims, if purchased.
    if (flared) {
      for (final left in [60.0, 327.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, 172, 13, 42),
            const Radius.circular(5),
          ),
          _paint(bodyShadow),
        );
      }
    }

    // Signature red LED-style taillights on both sides. These are rear lights,
    // independent of the purchased FRONT headlight type.
    for (final isLeft in [true, false]) {
      canvas.save();
      if (!isLeft) {
        canvas.translate(400, 0);
        canvas.scale(-1, 1);
      }
      final lamp = Path()
        ..moveTo(69, 156)
        ..quadraticBezierTo(82, 148, 100, 154)
        ..lineTo(158, 160)
        ..quadraticBezierTo(146, 172, 123, 174)
        ..lineTo(80, 171)
        ..close();
      canvas.drawPath(lamp, _paint(const Color(0xFF721E35)));
      final lightPipe = Path()
        ..moveTo(75, 159)
        ..quadraticBezierTo(91, 153, 113, 162)
        ..lineTo(151, 164)
        ..quadraticBezierTo(123, 169, 90, 165)
        ..close();
      canvas.drawPath(lightPipe, _paint(const Color(0xFFFF5E70)));
      canvas.drawLine(
        const Offset(87, 170),
        const Offset(121, 171),
        Paint()
          ..color = const Color(0xFFFFB4B8)
          ..strokeWidth = 2,
      );
      canvas.restore();
    }

    // Understated original badge, without using a trademarked logo.
    canvas.drawCircle(
        const Offset(200, 166), 5.5, _paint(const Color(0xFFEDF3F4)));
    canvas.drawCircle(const Offset(200, 166), 3.1, _paint(bodyShadow));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(162, 184, 76, 28),
        const Radius.circular(5),
      ),
      _paint(const Color(0xFF293441)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(166, 187, 68, 22),
        const Radius.circular(3),
      ),
      _paint(const Color(0xFFFFF5E5)),
    );
    final plate = TextPainter(
      text: const TextSpan(
        text: 'LITTLE US',
        style: TextStyle(
          color: Color(0xFF35465B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    plate.paint(canvas, Offset(200 - plate.width / 2, 193));

    // Rear bumper: sport upgrade gives a dark diffuser and twin exhaust tips.
    final bumper = Path()
      ..moveTo(67, 216)
      ..quadraticBezierTo(200, 230, 333, 216)
      ..lineTo(325, 235)
      ..quadraticBezierTo(200, 249, 75, 235)
      ..close();
    canvas.drawPath(
        bumper, _paint(sport ? const Color(0xFF29333C) : bodyShadow));
    canvas.drawLine(
      const Offset(89, 219),
      const Offset(311, 219),
      Paint()
        ..color = chrome.withValues(alpha: sport ? .30 : .75)
        ..strokeWidth = 2,
    );
    if (sport) {
      for (final x in [93.0, 276.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 227, 31, 8),
            const Radius.circular(4),
          ),
          _paint(const Color(0xFFB9C5D0)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 4, 229, 23, 4),
            const Radius.circular(3),
          ),
          _paint(const Color(0xFF414A55)),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RoadTripPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      !mapEquals(oldDelegate.equipped, equipped);
}
