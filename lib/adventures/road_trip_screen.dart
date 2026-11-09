import 'package:flutter/material.dart';
import '../store.dart';
import 'road_trip_painter.dart';
import 'road_trip_timeline.dart';
import 'sunset_beach_screen.dart';

/// Route: Garage -> RoadTripScreen -> SunsetBeachScreen -> Garage.
/// Does not persist fake progress, deduct hearts, or block navigation on network.
class RoadTripScreen extends StatefulWidget {
  const RoadTripScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<RoadTripScreen> createState() => _RoadTripScreenState();
}

class _RoadTripScreenState extends State<RoadTripScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: RoadTripTimeline.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _arrive();
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _arrive());
    } else {
      _controller.forward();
    }
  }

  void _arrive() {
    if (!mounted || _navigating) return;
    _navigating = true;
    _controller.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SunsetBeachScreen(store: widget.store),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF354F54),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RoadTripPainter(
                animation: _controller,
                equipped: widget.store.garageEquipped,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .34),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: .45),
                    ],
                    stops: const [0, .19, .72, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('OUR LITTLE ROAD TRIP',
                            style: TextStyle(
                              letterSpacing: 1.3,
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                      TextButton.icon(
                        onPressed: _arrive,
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white),
                        label: const Text('Skip',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RoadTripTimeline.caption(_controller.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black45)
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: _controller.value,
                            backgroundColor: const Color(0x55FFFFFF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFE0B7)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Every road is better with you ♡',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
