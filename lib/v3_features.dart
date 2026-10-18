import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'accessories.dart';
import 'photo_processor.dart';
import 'room_scenes.dart';
import 'store.dart';

const _ink = Color(0xFF594744), _rose = Color(0xFFE695A3);

class BedroomWallFrames extends StatelessWidget {
  const BedroomWallFrames({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final slot in ['a', 'b']) ...[
        if (slot == 'b') const SizedBox(width: 14),
        Expanded(
          child: _PhotoTile(
            key: ValueKey('bedroom-frame-$slot'),
            bytes: store.frameBytes[store.home?[slot]],
            name: store.home?['${slot}_name'] ?? 'Your person',
            compact: true,
          ),
        ),
      ],
    ],
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.bytes,
    required this.name,
    this.compact = false,
  });
  final Uint8List? bytes;
  final String name;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    label: "$name’s bedroom photo${bytes == null ? ', empty' : ''}",
    child: Container(
      padding: EdgeInsets.all(compact ? 4 : 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(compact ? 4 : 14),
        border: Border.all(
          color: const Color(0xFFC99B7D),
          width: compact ? 2 : 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x185E3A39),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 1 : 7),
        child: bytes == null
            ? ColoredBox(
                color: const Color(0xFFF3DEE5),
                child: Center(
                  child: Icon(
                    Icons.favorite_outline,
                    size: compact ? 18 : 34,
                    color: _rose,
                  ),
                ),
              )
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                gaplessPlayback: false,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
      ),
    ),
  );
}

class BedroomPhotoPanel extends StatefulWidget {
  const BedroomPhotoPanel({super.key, required this.store});
  final AppStore store;
  @override
  State<BedroomPhotoPanel> createState() => _BedroomPhotoPanelState();
}

class _BedroomPhotoPanelState extends State<BedroomPhotoPanel> {
  bool choosing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recover());
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final s = widget.store;
    final pending = s.prefs.getString('frame_picker_scope');
    try {
      final response = await ImagePicker().retrieveLostData();
      await s.prefs.remove('frame_picker_scope');
      if (!mounted || response.isEmpty || pending != s.widgetScope) return;
      if (response.files?.isNotEmpty == true) {
        await _preview(response.files!.first, pending!);
      } else {
        _message('Photo selection was interrupted. Please choose again.');
      }
    } catch (_) {
      /* No automatic upload of recovered files. */
    }
  }

  Future<void> _pick() async {
    if (choosing || widget.store.busy) return;
    final s = widget.store;
    final scope = s.widgetScope;
    if (scope == null) return;
    setState(() => choosing = true);
    try {
      await s.prefs.setString('frame_picker_scope', scope);
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      await s.prefs.remove('frame_picker_scope');
      if (file != null && mounted) await _preview(file, scope);
    } catch (_) {
      _message(
        'Could not open this photo. Try a JPEG or PNG from your gallery.',
      );
    } finally {
      if (mounted) setState(() => choosing = false);
    }
  }

  Future<void> _preview(XFile file, String scope) async {
    final s = widget.store;
    if (!mounted || s.widgetScope != scope) return;
    try {
      if (await file.length() > 12 * 1024 * 1024) {
        _message('Choose a photo smaller than 12 MB.');
        return;
      }
      final jpeg = await prepareFramePhoto(await file.readAsBytes());
      if (!mounted || s.widgetScope != scope) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('A little moment to share'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 220,
                  width: 220,
                  child: Image.memory(jpeg, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                Text(
                  s.demo
                      ? 'Demo photo: kept only for this session.'
                      : 'This replaces your frame and is visible to your partner. Location metadata is removed. Your original stays on your phone.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Share in our bedroom'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted && s.widgetScope == scope) {
        await s.run(() => s.uploadFrame(jpeg, scope));
      }
    } catch (e) {
      _message(
        e is FormatException
            ? e.message
            : 'This photo format could not be read. Try JPEG or PNG.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final locked = s.home?['photos_cleanup'] == true;
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 16, bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8F3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Two frames. One little home.',
            style: TextStyle(fontFamily: 'Lora', fontSize: 20, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'One photo from each of you. Choose something that feels like us.',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final slot in ['a', 'b']) ...[
                if (slot == 'b') const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: .9,
                        child: _PhotoTile(
                          bytes: s.frameBytes[s.home?[slot]],
                          name: s.home?['${slot}_name'] ?? 'Your person',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.home?['${slot}_name'] ?? 'Your person',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        s.home?[slot] == s.me
                            ? 'Your frame'
                            : s.home?[slot] == null
                            ? 'Waiting for your partner'
                            : 'Your partner’s frame',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (locked) ...[
            const Text(
              'Photo uploads are paused for home cleanup. Retry leaving, or resume uploads if you changed your mind.',
            ),
            TextButton(
              onPressed: s.busy ? null : () => s.run(s.cancelPhotoCleanup),
              child: const Text('Resume photo uploads'),
            ),
          ] else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: s.busy || choosing ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    choosing ? 'Preparing photo…' : 'Choose my photo',
                  ),
                ),
                if (s.frameBytes.containsKey(s.me) ||
                    s.frames.any(
                      (f) => f['owner'] == s.me && f['revision'] != null,
                    ))
                  TextButton(
                    onPressed: s.busy || choosing
                        ? null
                        : () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remove your photo?'),
                                content: const Text(
                                  'Your partner’s frame stays as it is.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Keep'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) await s.run(s.removeMyFrame);
                          },
                    child: const Text('Remove my photo'),
                  ),
              ],
            ),
          if (s.photoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s.photoError!),
            ),
          const SizedBox(height: 8),
          Text(
            s.demo
                ? 'Demo photos disappear when you restart or leave demo mode.'
                : 'Private to your home · max 1 MB each · syncs while the app is open',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class PetAccessoriesPanel extends StatelessWidget {
  const PetAccessoriesPanel({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final s = store;
    if (s.pet == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEED5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A tiny wardrobe',
            style: TextStyle(fontFamily: 'Lora', fontSize: 20, color: _ink),
          ),
          const Text(
            'Buy once with shared hearts. Both of you can dress your pet.',
          ),
          const SizedBox(height: 12),
          for (final item in petAccessories)
            Builder(
              builder: (context) {
                final owned =
                    item.id == 'none' || s.ownedAccessories.contains(item.id);
                final equipped = s.petAccessory == item.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 64,
                        child: PetPortrait(
                          kind: s.pet!['kind'],
                          accessory: item.id,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: s.busy || equipped
                            ? null
                            : () async {
                                if (!owned) {
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        'Buy ${item.name.toLowerCase()}?',
                                      ),
                                      content: Text(
                                        'Spend ${item.price} shared hearts? You have ${s.coins}. Both partners can use it.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: s.coins < item.price
                                              ? null
                                              : () => Navigator.pop(ctx, true),
                                          child: const Text('Buy & wear'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes != true) return;
                                }
                                await s.run(() => s.equipAccessory(item.id));
                              },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!owned && !equipped) ...[
                              const Icon(Icons.favorite_border, size: 15),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              equipped
                                  ? 'Wearing'
                                  : owned
                                  ? 'Wear'
                                  : '${item.price}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
