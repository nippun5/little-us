/// Fixed-duration, skippable transition between the Garage and Sunset Beach.
enum RoadTripStage { leaving, forest, coast, arriving }

class RoadTripTimeline {
  RoadTripTimeline._();
  static const duration = Duration(seconds: 8);

  static RoadTripStage stage(double progress) {
    if (progress < .16) return RoadTripStage.leaving;
    if (progress < .57) return RoadTripStage.forest;
    if (progress < .86) return RoadTripStage.coast;
    return RoadTripStage.arriving;
  }

  static String caption(double progress) => switch (stage(progress)) {
        RoadTripStage.leaving => 'Leaving our little garage...',
        RoadTripStage.forest => 'Through the forest, together',
        RoadTripStage.coast => 'The ocean is getting closer',
        RoadTripStage.arriving => 'Welcome to Sunset Beach!',
      };

  static double coastBlend(double progress) =>
      ((progress - .55) / .19).clamp(0.0, 1.0).toDouble();
}
