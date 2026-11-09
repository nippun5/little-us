import 'dart:math' as math;

/// A pet's *feet* position as a fraction of the room scene's width and height.
class PetPoint {
  const PetPoint(this.x, this.y);
  final double x;
  final double y;

  double distanceTo(PetPoint other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
}

/// Small walkable regions in FRONT of the furnishings in Little Us's rooms.
/// Prevents pets from appearing on walls, beds, sofas, plants and photo frames.
class PetMovement {
  PetMovement._();

  static const initial = PetPoint(0.16, 0.93);

  static PetPoint walkable(String room, PetPoint desired) {
    final x = desired.x.clamp(0.13, 0.88).toDouble();
    final (double low, double high) = switch (room) {
      'living' => (0.88, 0.955), // rug in front of sofa / coffee table
      'bedroom' => (0.87, 0.955), // floor in front of bed
      'garden' => (0.81, 0.96), // lawn in front of bench
      _ => (0.88, 0.955),
    };
    return PetPoint(x, desired.y.clamp(low, high).toDouble());
  }

  static PetPoint stepToward(PetPoint current, PetPoint target, double step) {
    if (!step.isFinite || step <= 0) return current;
    final distance = current.distanceTo(target);
    if (distance <= step || distance < 0.00001) return target;
    final part = step / distance;
    return PetPoint(current.x + (target.x - current.x) * part,
        current.y + (target.y - current.y) * part);
  }
}
