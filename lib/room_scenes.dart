import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'room.dart';

class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.room,
    required this.theme,
    this.petKind,
    this.accessory = 'none',
    this.bedroomFrames,
    this.onPlay,
    this.onNote,
    this.onDate,
  });
  final String room, theme;
  final String? petKind;
  final String accessory;
  final Widget? bedroomFrames;
  final VoidCallback? onPlay, onNote, onDate;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (room == 'living')
        Room(theme: theme, onPlay: onPlay, onNote: onNote, onDate: onDate)
      else
        Semantics(
          label: room == 'bedroom' ? 'Our cozy bedroom' : 'Our sunny garden',
          image: true,
          child: AspectRatio(
            aspectRatio: 1.35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(painter: ExtraRoomPainter(room, theme)),
            ),
          ),
        ),
      if (room == 'bedroom' && bedroomFrames != null)
        Positioned.fill(
          child: Align(
            alignment: const Alignment(-.38, -.83),
            child: FractionallySizedBox(
              widthFactor: .48,
              heightFactor: .25,
              child: bedroomFrames,
            ),
          ),
        ),
      if (petKind != null)
        Positioned(
          left: 16,
          bottom: 6,
          child: SizedBox(
            width: 78,
            height: 83,
            child: PetPortrait(kind: petKind!, accessory: accessory),
          ),
        ),
    ],
  );
}

class PetPortrait extends StatefulWidget {
  const PetPortrait({super.key, required this.kind, this.accessory = 'none'});
  final String kind;
  final String accessory;
  @override
  State<PetPortrait> createState() => _PetPortraitState();
}

class _PetPortraitState extends State<PetPortrait> {
  bool happy = false;
  Timer? reset;
  @override
  void dispose() {
    reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Our ${widget.kind}. Tap to say hello.',
    button: true,
    child: GestureDetector(
      onTap: () {
        setState(() => happy = true);
        reset?.cancel();
        reset = Timer(const Duration(milliseconds: 650), () {
          if (mounted) setState(() => happy = false);
        });
      },
      child: AnimatedScale(
        scale: happy ? 1.12 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: CustomPaint(
          painter: PetPainter(widget.kind, happy, widget.accessory),
          size: const Size(120, 120),
        ),
      ),
    ),
  );
}

class PetPainter extends CustomPainter {
  PetPainter(this.kind, this.happy, [this.accessory = 'none']);
  final String accessory;
  final String kind;
  final bool happy;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 120, s.height / 120);
    final p = Paint();
    void oval(double x, double y, double w, double h, Color color) {
      p.color = color;
      c.drawOval(Rect.fromLTWH(x, y, w, h), p);
    }

    void path(List<Offset> points, Color color) {
      p.color = color;
      c.drawPath(Path()..addPolygon(points, true), p);
    }

    const fur = Color(0xFFE8AD78),
        dark = Color(0xFF604A45),
        pink = Color(0xFFE298A2);
    oval(20, 102, 80, 10, const Color(0x20916B50));
    p
      ..color = fur
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(
      const Rect.fromLTWH(69, 60, 38, 40),
      -.5,
      math.pi * 1.3,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    oval(29, 51, 62, 55, fur);
    oval(35, 94, 22, 14, fur);
    oval(66, 94, 22, 14, fur);
    if (kind == 'cat') {
      path([
        const Offset(27, 43),
        const Offset(27, 9),
        const Offset(50, 29),
      ], fur);
      path([
        const Offset(70, 28),
        const Offset(96, 9),
        const Offset(95, 45),
      ], fur);
      path([
        const Offset(32, 30),
        const Offset(32, 18),
        const Offset(44, 29),
      ], pink);
      path([
        const Offset(77, 29),
        const Offset(90, 18),
        const Offset(90, 32),
      ], pink);
    } else {
      oval(19, 25, 23, 48, const Color(0xFFB77D56));
      oval(82, 25, 23, 48, const Color(0xFFB77D56));
    }
    oval(27, 23, 70, 58, fur);
    oval(44, 53, 39, 24, const Color(0xFFFFEAD2));
    for (final x in [45.0, 78.0]) {
      if (happy) {
        p
          ..color = dark
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        c.drawArc(Rect.fromLTWH(x - 5, 43, 10, 8), math.pi, math.pi, false, p);
        p.style = PaintingStyle.fill;
      } else {
        oval(x - 3, 44, 6, 8, dark);
        oval(x - 2, 45, 2, 2, Colors.white);
      }
    }
    oval(58, 55, 9, 6, dark);
    oval(34, 55, 11, 5, pink);
    oval(81, 55, 11, 5, pink);
    p
      ..color = dark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    c.drawArc(const Rect.fromLTWH(56, 61, 15, 9), 0, math.pi, false, p);
    p.style = PaintingStyle.fill;
    oval(44, 82, 33, 19, const Color(0xFFFFEAD2));
    if (accessory == 'collar') {
      p.color = const Color(0xFFE8BA62);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(36, 76, 51, 8),
          const Radius.circular(4),
        ),
        p,
      );
      oval(57, 80, 10, 12, const Color(0xFFFFDF83));
    } else if (accessory == 'bow') {
      path([
        const Offset(55, 77),
        const Offset(39, 69),
        const Offset(39, 88),
      ], pink);
      path([
        const Offset(62, 77),
        const Offset(79, 69),
        const Offset(79, 88),
      ], pink);
      oval(53, 73, 12, 12, const Color(0xFFB95F80));
    } else if (accessory == 'bandana') {
      path([
        const Offset(34, 76),
        const Offset(89, 76),
        const Offset(62, 99),
      ], const Color(0xFF73B5A6));
      oval(51, 81, 3, 3, Colors.white);
      oval(65, 86, 3, 3, Colors.white);
      oval(73, 80, 3, 3, Colors.white);
    } else if (accessory == 'crown') {
      path([
        const Offset(40, 25),
        const Offset(35, 5),
        const Offset(52, 14),
        const Offset(62, 1),
        const Offset(72, 14),
        const Offset(88, 5),
        const Offset(83, 25),
      ], const Color(0xFFE7B74D));
      oval(58, 14, 8, 8, pink);
    }
    if (happy) {
      p.color = pink;
      final heart = Path()
        ..moveTo(105, 22)
        ..cubicTo(89, 13, 99, 3, 105, 10)
        ..cubicTo(112, 3, 121, 13, 105, 22);
      c.drawPath(heart, p);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(PetPainter old) =>
      old.kind != kind || old.happy != happy || old.accessory != accessory;
}

class ExtraRoomPainter extends CustomPainter {
  ExtraRoomPainter(this.room, this.theme);
  final String room, theme;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 400, s.height / 300);
    final p = Paint();
    final accent = sofaColor(theme);
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double r = 0,
    ]) {
      p.color = color;
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        p,
      );
    }

    void oval(double x, double y, double w, double h, Color color) {
      p.color = color;
      c.drawOval(Rect.fromLTWH(x, y, w, h), p);
    }

    void line(
      double x,
      double y,
      double x2,
      double y2,
      Color color, [
      double w = 2,
    ]) {
      p
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x, y), Offset(x2, y2), p);
    }

    const cream = Color(0xFFFFF7E9),
        wood = Color(0xFFB88D73),
        green = Color(0xFF8EAF8B);
    if (room == 'bedroom') {
      rect(0, 0, 400, 300, const Color(0xFFE9E1EE));
      rect(0, 218, 400, 82, const Color(0xFFDEC7B9));
      oval(83, 236, 249, 52, const Color(0xFFF4E9DB));
      rect(273, 31, 76, 102, cream, 36);
      rect(280, 38, 62, 87, const Color(0xFF8D96BC), 30);
      oval(309, 49, 22, 22, const Color(0xFFFFE7AA));
      oval(317, 44, 22, 22, const Color(0xFF8D96BC));
      line(312, 44, 312, 126, cream, 4);
      line(279, 88, 342, 88, cream, 4);
      rect(95, 104, 170, 109, wood, 20);
      rect(101, 110, 158, 96, accent, 16);
      rect(81, 166, 199, 84, cream, 14);
      rect(81, 193, 199, 55, accent, 12);
      rect(104, 148, 64, 33, cream, 9);
      rect(184, 148, 64, 33, cream, 9);
      for (double x = 98; x < 270; x += 22) {
        line(x, 201, x, 239, Color.lerp(accent, Colors.white, .25)!, 2);
      }
      rect(90, 246, 9, 18, wood, 3);
      rect(260, 246, 9, 18, wood, 3);
      rect(299, 179, 55, 56, wood, 6);
      rect(303, 186, 47, 20, const Color(0xFFE0C4AB), 4);
      oval(322, 193, 7, 5, wood);
      line(326, 178, 326, 148, wood, 3);
      rect(308, 129, 37, 24, const Color(0xFFFFDDA3), 7);
      // Two interactive Flutter photo frames are overlaid above the bed.
    } else {
      rect(0, 0, 400, 300, const Color(0xFFDCEDE8));
      oval(283, 24, 44, 44, const Color(0xFFFFDE96));
      oval(24, 36, 60, 19, cream);
      oval(42, 25, 29, 29, cream);
      oval(168, 42, 65, 17, cream);
      rect(0, 165, 400, 135, const Color(0xFFADC6A0));
      for (double x = 0; x < 400; x += 30) {
        rect(x, 116, 23, 91, const Color(0xFFF4E9D5), 5);
      }
      rect(0, 141, 400, 9, const Color(0xFFE3D6BD));
      rect(0, 177, 400, 9, const Color(0xFFE3D6BD));
      oval(91, 226, 222, 49, const Color(0xFFE0DCC1));
      rect(121, 166, 160, 53, accent, 9);
      rect(115, 210, 172, 13, wood, 4);
      line(135, 222, 135, 246, wood, 6);
      line(265, 222, 265, 246, wood, 6);
      line(135, 180, 266, 180, Color.lerp(accent, Colors.white, .3)!, 3);
      line(135, 195, 266, 195, Color.lerp(accent, Colors.white, .3)!, 3);
      for (final x in [47.0, 322.0]) {
        rect(x, 208, 34, 36, const Color(0xFFD1A08A), 5);
        line(x + 17, 208, x + 17, 164, green, 4);
        oval(x - 2, 178, 22, 12, green);
        oval(x + 17, 170, 24, 12, green);
        for (int i = 0; i < 5; i++) {
          final a = i * math.pi * 2 / 5;
          oval(
            x + 9 + math.cos(a) * 10,
            153 + math.sin(a) * 10,
            16,
            16,
            accent,
          );
        }
        oval(x + 12, 156, 12, 12, const Color(0xFFFFDB83));
      }
      line(35, 25, 365, 25, wood, 1.5);
      for (double x = 50; x < 360; x += 44) {
        line(x, 25, x, 35, wood, 1);
        oval(x - 4, 34, 8, 11, const Color(0xFFFFEFBB));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(ExtraRoomPainter old) =>
      room != old.room || theme != old.theme;
}
