import 'dart:math' as math;

/// A point in the drawing's normalized 0..1 coordinate space.
class DoodlePoint {
  const DoodlePoint(this.x, this.y);
  final double x;
  final double y;

  factory DoodlePoint.fromJson(dynamic value) {
    final raw = value as List<dynamic>;
    return DoodlePoint((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
  }

  List<double> toJson() => [
        double.parse(x.toStringAsFixed(3)),
        double.parse(y.toStringAsFixed(3)),
      ];
}

class DoodleStroke {
  const DoodleStroke(
      {required this.color, required this.width, required this.points});
  final String color;
  final int width;
  final List<DoodlePoint> points;

  factory DoodleStroke.fromJson(dynamic value) {
    final raw = Map<String, dynamic>.from(value as Map);
    return DoodleStroke(
      color: raw['c'] as String,
      width: (raw['w'] as num).toInt(),
      points: (raw['p'] as List<dynamic>).map(DoodlePoint.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'c': color,
        'w': width,
        'p': points.map((p) => p.toJson()).toList(),
      };
}

class DoodleRules {
  static const maxStrokes = 60;
  static const maxPointsPerStroke = 160;
  static const maxPoints = 1400;
  static const colors = [
    '#455A64', // ink
    '#DE6B83', // blush
    '#628CC4', // blue
    '#60A483', // green
    '#E6A853', // ochre
    '#9475BC', // purple
  ];
  static const widths = [3, 5, 7];
  static const prompts = [
    'Draw half an animal',
    'Start a funny monster',
    'Invent our dream pet',
    'Draw a mysterious object',
    'Begin a silly portrait',
    'Make a magical creature',
  ];

  static int pointsIn(List<DoodleStroke> strokes) =>
      strokes.fold<int>(0, (total, stroke) => total + stroke.points.length);

  static String? validate(List<DoodleStroke> strokes) {
    if (strokes.isEmpty) return 'Draw a little something first.';
    if (strokes.length > maxStrokes || pointsIn(strokes) > maxPoints) {
      return 'This doodle is full. Undo a few strokes to continue.';
    }
    for (final stroke in strokes) {
      if (!colors.contains(stroke.color) ||
          !widths.contains(stroke.width) ||
          stroke.points.length < 2 ||
          stroke.points.length > maxPointsPerStroke) {
        return 'One of the strokes is invalid.';
      }
      for (final p in stroke.points) {
        if (!p.x.isFinite ||
            !p.y.isFinite ||
            p.x < 0 ||
            p.x > 1 ||
            p.y < 0 ||
            p.y > 1) {
          return 'Drawing points must stay inside the paper.';
        }
      }
    }
    return null;
  }

  static List<dynamic> encode(List<DoodleStroke> strokes) =>
      strokes.map((s) => s.toJson()).toList();

  static List<DoodleStroke> decode(dynamic value) =>
      value is List ? value.map(DoodleStroke.fromJson).toList() : [];
}

/// Screen-local drawing state. Never modifies the other partner's layer.
class DoodleDrawingState {
  final List<DoodleStroke> strokes = [];
  List<DoodlePoint> active = [];
  String color = DoodleRules.colors.first;
  int width = 5;

  int get pointCount => DoodleRules.pointsIn(strokes) + active.length;
  bool get isFull =>
      strokes.length >= DoodleRules.maxStrokes ||
      pointCount >= DoodleRules.maxPoints;

  void start(DoodlePoint point) {
    if (isFull) return;
    active = [point];
  }

  void add(DoodlePoint point) {
    if (active.isEmpty ||
        pointCount >= DoodleRules.maxPoints ||
        active.length >= DoodleRules.maxPointsPerStroke) return;
    final last = active.last;
    if ((last.x - point.x).abs() + (last.y - point.y).abs() < .003) return;
    active.add(point);
  }

  void finish() {
    if (active.isEmpty) return;
    if (active.length == 1) {
      if (pointCount >= DoodleRules.maxPoints) {
        active = [];
        return;
      }
      final p = active.first;
      active.add(DoodlePoint(math.min(1.0, p.x + .002), p.y));
    }
    strokes
        .add(DoodleStroke(color: color, width: width, points: List.of(active)));
    active = [];
  }

  void undo() {
    active = [];
    if (strokes.isNotEmpty) strokes.removeLast();
  }

  void clear() {
    active = [];
    strokes.clear();
  }
}

class CoupleDoodle {
  const CoupleDoodle({
    required this.id,
    required this.prompt,
    required this.starterName,
    required this.isMine,
    required this.isFinished,
    required this.started,
    required this.original,
    required this.addition,
  });

  final String id;
  final String prompt;
  final String starterName;
  final bool isMine;
  final bool isFinished;
  final DateTime started;
  final List<DoodleStroke> original;
  final List<DoodleStroke> addition;

  bool get canFinish => !isFinished && !isMine;

  factory CoupleDoodle.fromJson(Map<String, dynamic> data) => CoupleDoodle(
        id: data['id'].toString(),
        prompt: data['prompt'].toString(),
        starterName: data['starter_name']?.toString() ?? 'Partner',
        isMine: data['is_mine'] == true,
        isFinished: data['is_finished'] == true,
        started: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
            DateTime.now(),
        original: DoodleRules.decode(data['starter_strokes']),
        addition: DoodleRules.decode(data['finish_strokes']),
      );
}
