import 'package:flutter/material.dart';

Color sofaColor(String theme) => switch (theme) {
  'lilac' => const Color(0xFFB8A3D5),
  'mint' => const Color(0xFF8EB9A4),
  'rose' => const Color(0xFFD890A6),
  _ => const Color(0xFFEDAA8F),
};

class Room extends StatelessWidget {
  const Room({
    super.key,
    required this.theme,
    this.onPlay,
    this.onNote,
    this.onDate,
  });
  final String theme;
  final VoidCallback? onPlay, onNote, onDate;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.35,
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(painter: RoomPainter(theme)),
            ),
          ),
          Positioned(
            left: c.maxWidth * .39,
            top: c.maxHeight * .62,
            width: c.maxWidth * .25,
            height: c.maxHeight * .26,
            child: Semantics(
              label: 'Play Know me better',
              button: true,
              child: Tooltip(
                message: 'Play together',
                child: InkWell(
                  onTap: onPlay,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: c.maxWidth * .73,
            top: c.maxHeight * .24,
            width: c.maxWidth * .16,
            height: c.maxHeight * .22,
            child: Semantics(
              label: 'Leave a love note',
              button: true,
              child: Tooltip(
                message: 'Leave a note',
                child: InkWell(onTap: onNote),
              ),
            ),
          ),
          Positioned(
            left: c.maxWidth * .16,
            top: c.maxHeight * .18,
            width: c.maxWidth * .16,
            height: c.maxHeight * .20,
            child: Semantics(
              label: 'Set our next meeting',
              button: true,
              child: Tooltip(
                message: 'Our next meeting',
                child: InkWell(onTap: onDate),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RoomPainter extends CustomPainter {
  RoomPainter(this.theme);
  final String theme;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 300);
    final p = Paint();
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double radius = 0,
    ]) {
      p.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(radius),
        ),
        p,
      );
    }

    void oval(double x, double y, double w, double h, Color color) {
      p.color = color;
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), p);
    }

    void line(
      double x,
      double y,
      double x2,
      double y2,
      Color color, [
      double width = 2,
    ]) {
      p
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), Offset(x2, y2), p);
    }

    void path(List<Offset> points, Color color) {
      p.color = color;
      final q = Path()..addPolygon(points, true);
      canvas.drawPath(q, p);
    }

    const cream = Color(0xFFFFF8EA),
        brown = Color(0xFF916954),
        green = Color(0xFF779E82);
    rect(0, 0, 400, 300, const Color(0xFFF3E9E0));
    rect(0, 214, 400, 86, const Color(0xFFE8CCB0));
    line(0, 214, 400, 214, const Color(0xFFD5B596), 3);
    for (double i = 0; i < 7; i++) {
      line(i * 80 - 80, 300, i * 62, 214, const Color(0xFFDABDA0), 1);
    }
    // Arched window and gentle afternoon light.
    rect(155, 30, 105, 119, const Color(0xFFE5CFB4), 52);
    rect(163, 38, 89, 102, const Color(0xFFBCD5D7), 44);
    oval(215, 51, 22, 22, const Color(0xFFFFE7A2));
    path([
      const Offset(163, 111),
      const Offset(185, 90),
      const Offset(210, 108),
      const Offset(233, 86),
      const Offset(252, 109),
      const Offset(252, 140),
      const Offset(163, 140),
    ], const Color(0xFF9CB9A4));
    line(207, 40, 207, 140, cream, 5);
    line(163, 91, 252, 91, cream, 5);
    rect(151, 141, 113, 9, cream, 3);
    path([
      const Offset(166, 150),
      const Offset(253, 150),
      const Offset(345, 260),
      const Offset(239, 260),
    ], const Color(0x30FFF8D9));
    // Calendar and pinned note.
    rect(60, 57, 50, 53, const Color(0xFFE7D7C8), 5);
    rect(63, 53, 46, 50, cream, 5);
    rect(63, 53, 46, 12, const Color(0xFFE5968B), 5);
    line(73, 49, 73, 58, brown, 3);
    line(98, 49, 98, 58, brown, 3);
    for (double y = 74; y < 94; y += 10) {
      for (double x = 72; x < 103; x += 10) {
        oval(x, y, 3, 3, const Color(0xFFC5A797));
      }
    }
    rect(298, 78, 45, 48, const Color(0xFFFFE6A0), 3);
    oval(316, 73, 8, 8, const Color(0xFFCC8279));
    line(308, 94, 333, 94, const Color(0xFFD1AD65));
    line(308, 102, 328, 102, const Color(0xFFD1AD65));
    // Floor rug.
    oval(71, 224, 265, 62, const Color(0xFFD8B2A1));
    oval(80, 228, 247, 50, const Color(0xFFF6E8D5));
    oval(91, 233, 225, 39, const Color(0xFFEDDDC5));
    // Sofa feet, body, arms and pillows.
    rect(96, 216, 9, 21, brown, 3);
    rect(263, 216, 9, 21, brown, 3);
    rect(94, 151, 179, 68, sofaColor(theme), 18);
    rect(91, 188, 186, 39, sofaColor(theme), 10);
    rect(81, 178, 25, 47, sofaColor(theme), 10);
    rect(263, 178, 25, 47, sofaColor(theme), 10);
    line(112, 207, 257, 207, Color.lerp(sofaColor(theme), brown, .2)!, 2);
    line(184, 165, 184, 203, Color.lerp(sofaColor(theme), brown, .16)!, 2);
    rect(117, 171, 37, 32, const Color(0xFFFFEBC9), 9);
    rect(221, 169, 33, 34, const Color(0xFFF9F2E8), 9);
    line(231, 177, 245, 192, const Color(0xFFD9BEAB), 2);
    line(231, 187, 238, 194, const Color(0xFFD9BEAB), 2);
    // Coffee table and question cards.
    rect(173, 256, 6, 18, brown, 2);
    rect(235, 256, 6, 18, brown, 2);
    oval(153, 235, 106, 31, const Color(0xFFB18163));
    oval(153, 231, 106, 28, const Color(0xFFCBA386));
    rect(181, 233, 22, 17, const Color(0xFFD2BFE7), 3);
    rect(190, 237, 24, 17, const Color(0xFFFFF6E6), 3);
    final heart = Path()
      ..moveTo(202, 248)
      ..cubicTo(189, 240, 199, 236, 202, 241)
      ..cubicTo(207, 235, 215, 241, 202, 248);
    p.color = const Color(0xFFCE7C7D);
    canvas.drawPath(heart, p);
    oval(225, 238, 15, 9, cream);
    rect(225, 234, 14, 8, cream, 3);
    oval(227, 233, 10, 4, brown);
    // Side lamp.
    line(48, 134, 48, 225, brown, 4);
    oval(31, 222, 34, 7, brown);
    path([
      const Offset(30, 111),
      const Offset(65, 111),
      const Offset(76, 146),
      const Offset(19, 146),
    ], const Color(0xFFF9D998));
    oval(19, 140, 57, 12, const Color(0xFFE8C77F));
    // Plant.
    rect(327, 218, 30, 28, const Color(0xFFCC9783), 5);
    oval(327, 213, 30, 10, const Color(0xFFE0B09A));
    line(342, 217, 341, 159, green, 3);
    line(341, 195, 323, 177, green, 3);
    line(341, 187, 358, 167, green, 3);
    oval(311, 163, 22, 13, green);
    oval(347, 153, 24, 17, const Color(0xFF8BAA87));
    oval(331, 144, 15, 26, const Color(0xFF92AD8E));
    oval(345, 189, 24, 13, green);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RoomPainter oldDelegate) => oldDelegate.theme != theme;
}
