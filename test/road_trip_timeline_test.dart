import 'package:flutter_test/flutter_test.dart';
import 'package:little_us/adventures/road_trip_timeline.dart';

void main() {
  test('road trip transitions in order and finishes at destination', () {
    expect(RoadTripTimeline.stage(0), RoadTripStage.leaving);
    expect(RoadTripTimeline.stage(.3), RoadTripStage.forest);
    expect(RoadTripTimeline.stage(.7), RoadTripStage.coast);
    expect(RoadTripTimeline.stage(.99), RoadTripStage.arriving);
    expect(RoadTripTimeline.duration.inSeconds, 8);
  });

  test('coastal fade always stays between 0 and 1', () {
    expect(RoadTripTimeline.coastBlend(0), 0);
    expect(RoadTripTimeline.coastBlend(1), 1);
    expect(RoadTripTimeline.coastBlend(.64), closeTo(.47368, 1e-4));
  });
}
