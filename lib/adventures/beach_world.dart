import 'dart:math' as math;

/// Normalized world coordinates: (0,0) is the top left and (1,1) the bottom right.
/// Independent of device size so portrait and landscape use the same logic.
class BeachPoint {
  const BeachPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(BeachPoint other) =>
      math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));

  @override
  String toString() => 'BeachPoint($x, $y)';
}

class BeachSpot {
  const BeachSpot({
    required this.id,
    required this.name,
    required this.prompt,
    required this.location,
    required this.approach,
  });

  final String id;
  final String name;
  final String prompt;
  final BeachPoint location;
  final BeachPoint approach;
}

class BeachWorld {
  BeachWorld._();

  // A basic walkable sand rectangle. Replace with a navmesh when the beach
  // gets foreground props / buildings / complex obstacles in Milestone 3.
  static const minX = 0.07;
  static const maxX = 0.93;
  static const minY = 0.60;
  static const maxY = 0.92;
  static const initialMe = BeachPoint(0.44, 0.86);
  static const initialPartner = BeachPoint(0.56, 0.86);

  static const spots = <BeachSpot>[
    BeachSpot(
      id: 'picnic',
      name: 'Picnic blanket',
      prompt: 'A sunset picnic for two. Soon you will choose treats together.',
      location: BeachPoint(0.16, 0.78),
      approach: BeachPoint(0.27, 0.80),
    ),
    BeachSpot(
      id: 'shells',
      name: 'Seashells',
      prompt: 'Shells washed onto the shore. A tiny treasure hunt is coming.',
      location: BeachPoint(0.78, 0.66),
      approach: BeachPoint(0.71, 0.67),
    ),
    BeachSpot(
      id: 'bench',
      name: 'Sunset bench',
      prompt: 'A place to sit close and watch the water together.',
      location: BeachPoint(0.82, 0.84),
      approach: BeachPoint(0.73, 0.84),
    ),
    BeachSpot(
      id: 'photo',
      name: 'Photo spot',
      prompt: 'The best view for your first couple postcard.',
      location: BeachPoint(0.44, 0.61),
      approach: BeachPoint(0.44, 0.65),
    ),
  ];

  static BeachPoint clampToSand(BeachPoint point) => BeachPoint(
        point.x.clamp(minX, maxX).toDouble(),
        point.y.clamp(minY, maxY).toDouble(),
      );

  static BeachPoint stepToward(
    BeachPoint current,
    BeachPoint destination,
    double maximumDistance,
  ) {
    if (!maximumDistance.isFinite || maximumDistance <= 0) return current;
    final distance = current.distanceTo(destination);
    if (distance < 0.00001 || distance <= maximumDistance) {
      return destination;
    }
    final ratio = maximumDistance / distance;
    return BeachPoint(
      current.x + (destination.x - current.x) * ratio,
      current.y + (destination.y - current.y) * ratio,
    );
  }
}
