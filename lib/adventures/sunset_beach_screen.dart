import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../store.dart';
import 'avatar_creator_screen.dart';
import 'avatar_model.dart';
import 'avatar_preview.dart';
import 'avatar_repository.dart';
import 'beach_world.dart';
import 'beach_activities.dart';
import 'beach_activity_journal.dart';

/// Milestone 3C: interactive beach moments and locally saved progress.
/// Partner avatar follows a script; no live multiplayer or shared rewards yet.
class SunsetBeachScreen extends StatefulWidget {
  const SunsetBeachScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<SunsetBeachScreen> createState() => _SunsetBeachScreenState();
}

class _SunsetBeachScreenState extends State<SunsetBeachScreen>
    with SingleTickerProviderStateMixin {
  static const _cream = Color(0xFFFFFAF4);
  static const _ink = Color(0xFF443747);
  static const _coral = Color(0xFFC75E68);

  late final AvatarRepository _repository;
  late final BeachActivityJournal _journal;
  Map<String, BeachActivityRecord> _completed = {};
  late final Ticker _ticker;
  late final String? _homeScope;

  AvatarPair? _avatars;
  BeachPoint _mine = BeachWorld.initialMe;
  BeachPoint _companion = BeachWorld.initialPartner;
  BeachPoint _target = BeachWorld.initialMe;
  BeachSpot? _pendingSpot;
  Duration? _lastTick;
  double _walkPhase = 0;
  bool _walking = false;
  bool _companionWalking = false;
  bool _facingLeft = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = AvatarRepository(widget.store);
    _journal =
        BeachActivityJournal(widget.store.prefs, widget.store.widgetScope!);
    _completed = _journal.load();
    _homeScope = widget.store.widgetScope;
    _ticker = createTicker(_onFrame)..start();
    _loadAvatars();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _sameHome =>
      widget.store.widgetScope == _homeScope && widget.store.home != null;

  Future<void> _loadAvatars() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _avatars = null;
      _error = null;
    });
    try {
      final avatars = await _repository.load();
      if (!mounted) return;
      if (!_sameHome)
        throw StateError('Your home has changed. Reopen the beach.');
      setState(() => _avatars = avatars);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFrame(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null || _loading || _avatars == null || !_sameHome) return;

    final delta = (elapsed - previous).inMicroseconds / 1000000;
    final dt = delta.clamp(0.0, 0.05).toDouble();
    if (dt == 0) return;

    // The normalized-world movement rate is consistent between phone sizes.
    final nextMe = BeachWorld.stepToward(_mine, _target, 0.26 * dt);
    final stillMoving = nextMe.distanceTo(_target) > 0.002;
    final behind = BeachWorld.clampToSand(
      BeachPoint(nextMe.x + (nextMe.x > .83 ? -.09 : .09), nextMe.y + .025),
    );
    final nextCompanion = BeachWorld.stepToward(_companion, behind, 0.24 * dt);
    final following = nextCompanion.distanceTo(behind) > 0.006;

    if (stillMoving || _walking || following || _companionWalking) {
      setState(() {
        _mine = nextMe;
        _companion = nextCompanion;
        _walking = stillMoving;
        _companionWalking = following;
        if (stillMoving || following) _walkPhase += dt * 14;
      });
    }

    if (!stillMoving && _pendingSpot != null) {
      final selected = _pendingSpot!;
      _pendingSpot = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sameHome) _showSpot(selected);
      });
    }
  }

  void _goTo(BeachPoint position, {BeachSpot? spot}) {
    if (_loading || _avatars == null || !_sameHome) return;
    final safe = BeachWorld.clampToSand(position);
    setState(() {
      _pendingSpot = spot;
      _target = safe;
      _facingLeft = safe.x < _mine.x;
      _walking = _mine.distanceTo(safe) > 0.002;
    });

    // If standing on the hotspot already, open it without waiting for a frame.
    if (spot != null && !_walking) {
      _pendingSpot = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sameHome) _showSpot(spot);
      });
    }
  }

  void _goToSpot(BeachSpot spot) => _goTo(spot.approach, spot: spot);

  Future<void> _showSpot(BeachSpot spot) async {
    if (!_sameHome || _avatars == null) return;
    final result = await BeachActivities.open(
      context,
      id: spot.id,
      pair: _avatars!,
      myName: widget.store.myName,
      partnerName: widget.store.partner,
      previous: _completed[spot.id],
    );
    if (!mounted || !_sameHome || result == null) return;
    final record = BeachActivityRecord(
      id: result.id,
      summary: result.summary,
      caption: result.caption,
      completedAt: DateTime.now().toUtc().toIso8601String(),
    );
    try {
      await _journal.save(record);
      if (!mounted || !_sameHome) return;
      setState(() => _completed = _journal.load());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved on this device: ${result.summary}'),
      ));
    } catch (_) {
      if (!mounted || !_sameHome) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save beach progress on this device.'),
      ));
    }
  }

  static IconData _spotIcon(String id) => switch (id) {
        'picnic' => Icons.lunch_dining_rounded,
        'shells' => Icons.spa_rounded,
        'bench' => Icons.chair_alt_rounded,
        'photo' => Icons.photo_camera_rounded,
        _ => Icons.place_rounded,
      };

  Widget _avatarAt({
    required BeachPoint point,
    required CoupleAvatar avatar,
    required String name,
    required double worldWidth,
    required double worldHeight,
    required bool walking,
    required bool facingLeft,
    required bool companion,
  }) {
    final depth = 0.87 + (point.y - BeachWorld.minY) * .55;
    // In landscape, constrain avatars by stage HEIGHT too (not just width).
    final preferredWidth =
        (worldWidth * .17 * depth).clamp(38.0, 105.0).toDouble();
    final width = math.min(preferredWidth, math.max(24.0, worldHeight * .47));
    final height = width * 4 / 3;
    final bounce = walking ? math.sin(_walkPhase) * 3.0 : 0.0;

    return Positioned(
      left: (point.x * worldWidth - width / 2)
          .clamp(0.0, worldWidth - width)
          .toDouble(),
      top: (point.y * worldHeight - height - 5 + bounce)
          .clamp(0.0, worldHeight - height)
          .toDouble(),
      width: width,
      height: height,
      child: IgnorePointer(
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: width + 14),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: companion
                    ? const Color(0xB9334852)
                    : const Color(0xC0553242),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: math.max(9.0, width / 7),
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(
                child: Transform.flip(
              flipX: facingLeft,
              child: Transform.rotate(
                angle: walking ? math.sin(_walkPhase) * .037 : 0,
                child: AvatarPreview(
                    avatar: avatar, walkPhase: walking ? _walkPhase : 0),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _spotMarker(BeachSpot spot, double width, double height) {
    final left = (spot.location.x * width - 39)
        .clamp(0.0, math.max(0.0, width - 78))
        .toDouble();
    final top = (spot.location.y * height - 60)
        .clamp(0.0, math.max(0.0, height - 60))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: 78,
      height: 60,
      child: Semantics(
        label: 'Walk to ${spot.name}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('beach_spot_${spot.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => _goToSpot(spot),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFFAF4),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 7)
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(_spotIcon(spot.id), color: _coral, size: 21),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xC6333035),
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(
                      _completed.containsKey(spot.id)
                          ? '✓ ${spot.name}'
                          : spot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene() => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pair = _avatars!;

        final characters = <Widget>[
          _avatarAt(
              point: _mine,
              avatar: pair.mine,
              name: widget.store.myName,
              worldWidth: width,
              worldHeight: height,
              walking: _walking,
              facingLeft: _facingLeft,
              companion: false),
          _avatarAt(
              point: _companion,
              avatar: pair.partner,
              name: widget.store.partner,
              worldWidth: width,
              worldHeight: height,
              walking: _companionWalking,
              facingLeft: !_facingLeft,
              companion: true),
        ];

        // Render the character nearer the horizon first.
        if (_mine.y > _companion.y) {
          final back = characters.removeLast();
          characters.insert(0, back);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              _goTo(BeachPoint(details.localPosition.dx / width,
                  details.localPosition.dy / height));
            },
            child: Stack(fit: StackFit.expand, children: [
              const _BeachBackdrop(),
              // A light sand tint makes stylized characters readable over a photo.
              const DecoratedBox(
                  decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x15FFE6C8),
                      Color(0x33EAB17C)
                    ],
                    stops: [
                      0,
                      .55,
                      1
                    ]),
              )),
              ...BeachWorld.spots
                  .map((spot) => _spotMarker(spot, width, height)),
              ...characters,
              const Positioned(
                  left: 9,
                  top: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Color(0xAA222431),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Tap the sand to walk',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12))),
                  )),
            ]),
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    if (!_sameHome) {
      return Scaffold(
          appBar: AppBar(title: const Text('Sunset Beach')),
          body: const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Your home changed. Close this screen and open the beach again.'))));
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text('Sunset Beach'),
        actions: [
          IconButton(
              tooltip: 'Reload saved avatars',
              onPressed: _loading ? null : _loadAvatars,
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _avatars == null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error ?? 'Could not load your avatars.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _loadAvatars, child: const Text('Retry')),
                  ]),
                ))
              : SafeArea(
                  top: false,
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('A little escape for two',
                                style: TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 21)),
                            const SizedBox(height: 3),
                            Text(
                                _avatars!.partnerSaved
                                    ? 'Explore with your partner’s saved avatar (companion mode).'
                                    : 'Your partner has not created an avatar yet; using a preview companion.',
                                style: const TextStyle(
                                    color: Color(0xFF817580), fontSize: 12)),
                          ]),
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _scene(),
                    )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 18, color: _coral),
                        const SizedBox(width: 5),
                        const Expanded(
                            child: Text(
                                'Tap a location or choose a destination below.',
                                style: TextStyle(fontSize: 12, color: _ink))),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                              builder: (_) =>
                                  AvatarCreatorScreen(store: widget.store),
                            ));
                            if (mounted && _sameHome) await _loadAvatars();
                          },
                          icon: const Icon(Icons.face_rounded, size: 18),
                          label: const Text('Edit'),
                        ),
                      ]),
                    ),
                    SizedBox(
                        height: 56,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(12, 2, 12, 7),
                          children: [
                            for (final spot in BeachWorld.spots)
                              Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ActionChip(
                                    key: ValueKey('beach_action_${spot.id}'),
                                    avatar: Icon(_spotIcon(spot.id),
                                        size: 17, color: _coral),
                                    label: Text(_completed.containsKey(spot.id)
                                        ? '✓ ${spot.name}'
                                        : spot.name),
                                    onPressed: () => _goToSpot(spot),
                                  )),
                          ],
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '${_completed.length}/4 beach activities completed',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF817580),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ])),
    );
  }
}

/// Bundled photo is preferred for offline use. Until it is added, display the
/// freely licensed reference photo from Wikimedia, then an offline gradient.
class _BeachBackdrop extends StatelessWidget {
  const _BeachBackdrop();

  static const _photo =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/'
      'Sand_beach_at_sunset_%28Unsplash%29.jpg/'
      '1280px-Sand_beach_at_sunset_%28Unsplash%29.jpg';

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/adventures/sunset_beach.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          _photo,
          fit: BoxFit.cover,
          loadingBuilder: (context, image, loading) => loading == null
              ? image
              : const Stack(fit: StackFit.expand, children: [
                  _FallbackBeach(),
                  Center(child: CircularProgressIndicator(color: Colors.white)),
                ]),
          errorBuilder: (_, __, ___) => const _FallbackBeach(),
        ),
      );
}

class _FallbackBeach extends StatelessWidget {
  const _FallbackBeach();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .32, .48, .61, 1],
          colors: [
            Color(0xFF667EAB),
            Color(0xFFF3B7A0),
            Color(0xFF6AABBE),
            Color(0xFFB3CAC2),
            Color(0xFFE5C69D)
          ],
        )),
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Offline scenery preview — add sunset_beach.jpg for the real beach photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF665643), fontSize: 11)),
            )),
      );
}
