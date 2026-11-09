import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/pets/pet_movement.dart';

void main() {
  test('pets never walk onto living room wall or sofa', () {
    final p = PetMovement.walkable('living', const PetPoint(.5, .13));
    expect(p.y, greaterThanOrEqualTo(.88));
    expect(p.y, lessThanOrEqualTo(.955));
  });

  test('bedroom and garden maintain distinct walkable floors', () {
    expect(PetMovement.walkable('bedroom', const PetPoint(.5, 0)).y, .87);
    expect(PetMovement.walkable('garden', const PetPoint(.5, 0)).y, .81);
    expect(PetMovement.walkable('garden', const PetPoint(5, 5)).x, .88);
  });

  test('movement advances, then stops exactly at target', () {
    const start = PetPoint(.1, .9);
    const target = PetPoint(.8, .9);
    final next = PetMovement.stepToward(start, target, .2);
    expect(next.x, closeTo(.3, 1e-8));
    final arrived = PetMovement.stepToward(next, target, 5);
    expect(arrived.distanceTo(target), 0);
  });

  test('zero or non-finite movement does not move', () {
    const p = PetPoint(.2, .8);
    expect(PetMovement.stepToward(p, const PetPoint(.7, .8), -1).x, .2);
    expect(PetMovement.stepToward(p, const PetPoint(.7, .8), double.nan).x, .2);
  });
}
