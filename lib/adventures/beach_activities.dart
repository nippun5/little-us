import 'package:flutter/material.dart';
import 'avatar_preview.dart';
import 'beach_activity_journal.dart';
import 'avatar_repository.dart';

class BeachActivityResult {
  const BeachActivityResult(this.id, this.summary, {this.caption = ''});
  final String id;
  final String summary;
  final String caption;
}

/// Four actual touch activities. This is offline/local Milestone 3C; no
/// unsupported claims of live play, hearts, exported photos, or server saves.
class BeachActivities {
  BeachActivities._();

  static Future<BeachActivityResult?> open(
    BuildContext context, {
    required String id,
    required AvatarPair pair,
    required String myName,
    required String partnerName,
    BeachActivityRecord? previous,
  }) =>
      showModalBottomSheet<BeachActivityResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: const Color(0xFFFFFAF4),
        builder: (sheetContext) => _ActivitySheet(
          id: id,
          pair: pair,
          myName: myName,
          partnerName: partnerName,
          previous: previous,
        ),
      );
}

class _ActivitySheet extends StatefulWidget {
  const _ActivitySheet(
      {required this.id,
      required this.pair,
      required this.myName,
      required this.partnerName,
      this.previous});
  final String id;
  final AvatarPair pair;
  final String myName;
  final String partnerName;
  final BeachActivityRecord? previous;

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  static const coral = Color(0xFFC75E68);
  final TextEditingController _caption = TextEditingController();
  String? _snack;
  String? _drink;
  String _benchPose = 'Hold hands';
  String _photoPose = 'Side by side';
  final Set<int> _turned = {};
  static const Set<int> _shellTiles = {1, 4, 7};

  @override
  void initState() {
    super.initState();
    final old = widget.previous;
    if (widget.id == 'bench' && old != null) {
      const prefix = 'Shared sunset moment: ';
      if (old.summary.startsWith(prefix)) {
        final pose = old.summary.substring(prefix.length);
        if (const ['Hold hands', 'Lean closer', 'Watch the waves']
            .contains(pose)) {
          _benchPose = pose;
        }
      }
    }
    if (widget.id == 'picnic' && old != null) {
      const prefix = 'Picnic with ';
      if (old.summary.startsWith(prefix)) {
        final previousChoices =
            old.summary.substring(prefix.length).split(' and ');
        if (previousChoices.length == 2) {
          if (const ['Strawberries 🍓', 'Sandwiches 🥪', 'Cookies 🍪']
              .contains(previousChoices.first)) _snack = previousChoices.first;
          if (const ['Lemonade 🍋', 'Iced tea 🧋', 'Hot chocolate ☕']
              .contains(previousChoices.last)) _drink = previousChoices.last;
        }
      }
    }
    if (widget.id == 'photo' && old != null) {
      _caption.text = old.caption;
      const prefix = 'Postcard pose: ';
      if (old.summary.startsWith(prefix)) {
        final pose = old.summary.substring(prefix.length);
        if (const ['Side by side', 'Wave hello', 'Heart pose'].contains(pose)) {
          _photoPose = pose;
        }
      }
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  String get title => switch (widget.id) {
        'picnic' => 'Our beach picnic',
        'shells' => 'Seashell hunt',
        'bench' => 'Sunset together',
        'photo' => 'Our first postcard',
        _ => 'Beach moment',
      };
  String get intro => switch (widget.id) {
        'picnic' => 'Choose a snack and drink for your imaginary picnic.',
        'shells' => 'Turn the sand tiles to find three hidden shells.',
        'bench' => 'Choose a cozy moment for your two avatars.',
        'photo' =>
          'Pick a pose and write a caption for a local postcard draft.',
        _ => '',
      };
  int get found => _turned.where(_shellTiles.contains).length;
  bool get canComplete => switch (widget.id) {
        'picnic' => _snack != null && _drink != null,
        'shells' => found == 3,
        'bench' || 'photo' => true,
        _ => false,
      };

  void _complete() {
    if (!canComplete) return;
    final result = switch (widget.id) {
      'picnic' =>
        BeachActivityResult('picnic', 'Picnic with $_snack and $_drink'),
      'shells' =>
        const BeachActivityResult('shells', 'Found all three seashells'),
      'bench' =>
        BeachActivityResult('bench', 'Shared sunset moment: $_benchPose'),
      'photo' => BeachActivityResult('photo', 'Postcard pose: $_photoPose',
          caption: _caption.text.trim()),
      _ => null,
    };
    if (result != null) Navigator.of(context).pop(result);
  }

  Widget _choices(
          List<String> items, String? current, ValueChanged<String> select) =>
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (final choice in items)
          ChoiceChip(
              label: Text(choice),
              selected: choice == current,
              selectedColor: const Color(0xFFF7DCE0),
              onSelected: (_) => setState(() => select(choice))),
      ]);

  Widget _avatars({bool onBench = false}) => Container(
        height: 154,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF6B7A1),
                  Color(0xFFF2D2AF),
                  Color(0xFFF0E0C8)
                ])),
        child: Stack(alignment: Alignment.bottomCenter, children: [
          if (onBench)
            Positioned(
                bottom: 23,
                left: 40,
                right: 40,
                child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                        color: const Color(0xFF916C60),
                        borderRadius: BorderRadius.circular(8)))),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                    width: 92,
                    height: 132,
                    child: AvatarPreview(avatar: widget.pair.mine)),
                SizedBox(width: onBench && _benchPose == 'Lean closer' ? 0 : 8),
                SizedBox(
                    width: 92,
                    height: 132,
                    child: AvatarPreview(avatar: widget.pair.partner)),
              ]),
          if (onBench)
            const Positioned(
                bottom: 0,
                child: Text('♡', style: TextStyle(fontSize: 27, color: coral))),
        ]),
      );

  Widget _picnic() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choose our snack',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _choices(const ['Strawberries 🍓', 'Sandwiches 🥪', 'Cookies 🍪'],
            _snack, (choice) => _snack = choice),
        const SizedBox(height: 20),
        const Text('Choose our drink',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _choices(const ['Lemonade 🍋', 'Iced tea 🧋', 'Hot chocolate ☕'],
            _drink, (choice) => _drink = choice),
        const SizedBox(height: 18),
        _avatars(),
        const SizedBox(height: 10),
        Text(
            _snack == null || _drink == null
                ? 'Pick both to prepare the picnic.'
                : '${widget.myName} and ${widget.partnerName} have a lovely picnic ready!',
            textAlign: TextAlign.center),
      ]);

  Widget _shells() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Seashells discovered: $found / 3',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35),
          itemCount: 9,
          itemBuilder: (context, i) {
            final turned = _turned.contains(i);
            final shell = _shellTiles.contains(i);
            return Semantics(
              label: turned
                  ? (shell ? 'Found shell' : 'Empty sand')
                  : 'Turn sand tile ${i + 1}',
              button: !turned,
              child: InkWell(
                key: ValueKey('shell_tile_$i'),
                onTap: turned ? null : () => setState(() => _turned.add(i)),
                borderRadius: BorderRadius.circular(15),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: turned
                          ? const Color(0xFFFFF4E3)
                          : const Color(0xFFE8C69B),
                      borderRadius: BorderRadius.circular(15)),
                  child: Center(
                      child: Text(
                          !turned
                              ? '✦'
                              : shell
                                  ? '🐚'
                                  : '·',
                          style:
                              TextStyle(fontSize: shell && turned ? 34 : 25))),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(found == 3
            ? 'All three treasures found!'
            : 'Tap a tile to search beneath the sand.'),
      ]);

  Widget _bench() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _avatars(onBench: true),
        const SizedBox(height: 14),
        const Text('How should we enjoy the sunset?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        _choices(const ['Hold hands', 'Lean closer', 'Watch the waves'],
            _benchPose, (choice) => _benchPose = choice),
        const SizedBox(height: 12),
        Text('A little moment for ${widget.myName} and ${widget.partnerName}.'),
        const Text(
            'Your partner’s avatar is a scripted companion, not a live player.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
      ]);

  Widget _photo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _postcardPreview(),
        const SizedBox(height: 12),
        const Text('Choose our pose',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _choices(const ['Side by side', 'Wave hello', 'Heart pose'], _photoPose,
            (choice) => _photoPose = choice),
        const SizedBox(height: 14),
        TextField(
          controller: _caption,
          maxLength: 120,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Postcard caption',
              hintText: 'Every road is better with you…'),
          onChanged: (_) => setState(() {}),
        ),
        const Text(
            'This is a local, in-app postcard draft—not an exported image yet.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
      ]);

  Widget _postcardPreview() => AspectRatio(
        aspectRatio: 1.55,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/adventures/sunset_beach.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                            Color(0xFFF2A98D),
                            Color(0xFFF3D3AF),
                            Color(0xFFA0CBD1)
                          ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)))),
              Positioned(
                  bottom: 16,
                  left: 4,
                  right: 4,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: 102,
                            width: 75,
                            child: AvatarPreview(avatar: widget.pair.mine)),
                        SizedBox(width: _photoPose == 'Side by side' ? 13 : 1),
                        SizedBox(
                            height: 102,
                            width: 75,
                            child: AvatarPreview(avatar: widget.pair.partner)),
                      ])),
              if (_photoPose == 'Heart pose')
                const Positioned(
                    right: 12,
                    bottom: 12,
                    child: Text('❤️', style: TextStyle(fontSize: 28))),
              if (_photoPose == 'Wave hello')
                const Positioned(
                    right: 12,
                    bottom: 12,
                    child: Icon(Icons.waving_hand_rounded,
                        color: Colors.white, size: 28)),
              Positioned(
                  left: 10,
                  right: 10,
                  top: 12,
                  child: Text(
                      _caption.text.trim().isEmpty
                          ? 'Our Sunset Beach'
                          : _caption.text.trim(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 5)
                          ]))),
            ])),
      );

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          height:
              ((MediaQuery.sizeOf(context).height - viewInsets.bottom - 28) *
                      .82)
                  .clamp(165.0, MediaQuery.sizeOf(context).height * .76)
                  .toDouble(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(intro, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  if (widget.previous != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Last saved: ${widget.previous!.summary}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                  Expanded(
                      child: ListView(children: [
                    if (widget.id == 'picnic') _picnic(),
                    if (widget.id == 'shells') _shells(),
                    if (widget.id == 'bench') _bench(),
                    if (widget.id == 'photo') _photo(),
                  ])),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('complete_beach_activity'),
                    onPressed: canComplete ? _complete : null,
                    icon: const Icon(Icons.favorite_rounded),
                    label: Text(widget.id == 'photo'
                        ? 'Save postcard draft'
                        : 'Finish this moment'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
