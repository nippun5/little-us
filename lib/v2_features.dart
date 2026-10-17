import 'package:flutter/material.dart';
import 'store.dart';
import 'room_scenes.dart';

const _ink = Color(0xFF443747),
    _coral = Color(0xFFC75E68),
    _lilac = Color(0xFFEDE3F6),
    _mint = Color(0xFFE2EFE5);
Widget _title(String t) => Text(
  t,
  style: const TextStyle(
    fontFamily: 'Lora',
    fontSize: 23,
    fontWeight: FontWeight.w600,
    color: _ink,
  ),
);
Widget _panel(Widget child, {Color color = _lilac}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(24),
  ),
  child: child,
);

class RoomPicker extends StatelessWidget {
  const RoomPicker({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children:
        const {
          'living': 'Living room',
          'bedroom': 'Bedroom',
          'garden': 'Garden',
        }.entries.map((entry) {
          final unlocked = store.unlockedRooms.contains(entry.key);
          return ChoiceChip(
            label: Text(entry.value),
            selected: store.currentRoom == entry.key,
            avatar: Icon(
              unlocked
                  ? switch (entry.key) {
                      'bedroom' => Icons.bed_outlined,
                      'garden' => Icons.local_florist_outlined,
                      _ => Icons.weekend_outlined,
                    }
                  : Icons.lock_outline,
              size: 18,
            ),
            onSelected: store.busy
                ? null
                : (_) async {
                    if (unlocked) {
                      await store.selectRoom(entry.key);
                      return;
                    }
                    final cost = entry.key == 'bedroom' ? 80 : 120;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Unlock the ${entry.value.toLowerCase()}?'),
                        content: Text(
                          'Spend $cost shared hearts. Both of you will own this room. Your balance is ${store.coins} hearts.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Maybe later'),
                          ),
                          FilledButton(
                            onPressed: store.coins < cost
                                ? null
                                : () => Navigator.pop(c, true),
                            child: Text('Unlock · $cost'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await store.run(() => store.unlockRoom(entry.key));
                    }
                  },
          );
        }).toList(),
  );
}

class PetPanel extends StatelessWidget {
  const PetPanel({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final pet = store.pet;
    if (pet == null) {
      return _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 70,
                  height: 74,
                  child: PetPortrait(kind: 'cat'),
                ),
                const SizedBox(width: 12),
                Expanded(child: _title('A little friend\nfor our home.')),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Adopt a cat or a dog together. Free to adopt, always happy to see you.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: store.busy
                  ? null
                  : () => _editPet(context, store, adopting: true),
              icon: const Icon(Icons.pets),
              label: const Text('Meet our pet'),
            ),
          ],
        ),
        color: _mint,
      );
    }
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 92,
                child: PetPortrait(kind: pet['kind']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(pet['name']),
                    Text('Bond level ${store.petLevel} · ${pet['xp']} XP'),
                    TextButton(
                      onPressed: store.busy
                          ? null
                          : () => _editPet(context, store, adopting: false),
                      child: const Text('Rename'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ((pet['xp'] as int) % 20) / 20,
            color: _coral,
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final action in ['feed', 'play'])
                FilledButton.tonalIcon(
                  onPressed: store.busy || store.petCareToday.contains(action)
                      ? null
                      : () => store.run(() => store.careForPet(action)),
                  icon: Icon(
                    action == 'feed'
                        ? Icons.restaurant
                        : Icons.sports_baseball_outlined,
                  ),
                  label: Text(
                    store.petCareToday.contains(action)
                        ? '${action == 'feed' ? 'Fed' : 'Played'} today'
                        : action == 'feed'
                        ? 'Feed · +2 XP'
                        : 'Play · +3 XP',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Each of you can feed and play once per UTC day. No hunger, lost progress, or missed-day penalties.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
      color: _mint,
    );
  }
}

Future<void> _editPet(
  BuildContext context,
  AppStore store, {
  required bool adopting,
}) async {
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _PetDialog(pet: adopting ? null : store.pet),
  );
  if (result != null) {
    await store.run(
      () => adopting
          ? store.adoptPet(result['kind']!, result['name']!)
          : store.renamePet(result['name']!),
    );
  }
}

class _PetDialog extends StatefulWidget {
  const _PetDialog({this.pet});
  final Map<String, dynamic>? pet;
  @override
  State<_PetDialog> createState() => _PetDialogState();
}

class _PetDialogState extends State<_PetDialog> {
  late final name = TextEditingController(text: widget.pet?['name'] ?? 'Mochi');
  String kind = 'cat';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.pet == null ? 'Meet your little friend' : 'A new name'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pet == null) ...[
            SizedBox(width: 120, height: 120, child: PetPortrait(kind: kind)),
            Wrap(
              spacing: 12,
              children: [
                for (final value in ['cat', 'dog'])
                  ChoiceChip(
                    label: Text(value == 'cat' ? 'Cat' : 'Dog'),
                    selected: kind == value,
                    onSelected: (_) => setState(() => kind = value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          TextField(
            controller: name,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Pet name'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, {
                'kind': kind,
                'name': name.text.trim(),
              }),
        child: Text(widget.pet == null ? 'Adopt for free' : 'Save name'),
      ),
    ],
  );
}

Future<bool> confirmWidgetSharing(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Put a note on your home screen?'),
        content: const Text(
          'This saves the selected note on this device for the system widget. Anyone who can view your home screen may read it. Updates arrive when Little us syncs; the widget keeps the last note while the app is closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Enable widget'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> pinFridgeNote(
  BuildContext context,
  AppStore store,
  String id,
) async {
  if (!store.fridgeBridge.supported) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Home-screen widgets are available in the Android and iOS builds.',
        ),
      ),
    );
    return;
  }
  if (!store.widgetEnabled && !await confirmWidgetSharing(context)) return;
  await store.run(() => store.pinWidgetNote(id));
}

class FridgeWidgetPanel extends StatelessWidget {
  const FridgeWidgetPanel({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.widgets_outlined, color: _coral),
            const SizedBox(width: 10),
            Expanded(child: _title('A note, closer to you.')),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Keep a little love note on your phone’s home screen.'),
        const SizedBox(height: 8),
        if (!store.fridgeBridge.supported)
          const Text(
            'Available on Android and iOS. The web demo does not install system widgets.',
            style: TextStyle(fontSize: 12),
          )
        else ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show notes in the widget'),
            value: store.widgetEnabled,
            onChanged: store.busy
                ? null
                : (v) async {
                    if (v && !await confirmWidgetSharing(context)) return;
                    await store.run(() => store.setWidgetEnabled(v));
                  },
          ),
          if (store.widgetEnabled) ...[
            Text(
              store.pinnedNoteId == null
                  ? 'Showing: latest note from your partner'
                  : 'Showing: your pinned note (or latest partner note if deleted)',
              style: const TextStyle(fontSize: 12),
            ),
            if (store.widgetNote != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  store.widgetNote!['body'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Lora', fontSize: 18),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: store.busy
                      ? null
                      : () => store.run(() => store.pinWidgetNote(null)),
                  child: const Text('Use latest partner note'),
                ),
                FilledButton.icon(
                  onPressed: store.busy
                      ? null
                      : () async {
                          try {
                            final requested = await store.fridgeBridge
                                .requestPin();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    requested
                                        ? 'Confirm the widget on your home screen.'
                                        : 'Long-press your home screen, open Widgets, then choose Little us. On iPhone, tap Edit → Add Widget.',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not open the widget picker. Add Little us from your home-screen widget gallery.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.add_to_home_screen, size: 17),
                  label: const Text('Add widget'),
                ),
              ],
            ),
          ],
          if (store.widgetError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                store.widgetError!,
                style: const TextStyle(color: _coral, fontSize: 12),
              ),
            ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Refreshes when this app syncs, not live while closed. The widget shows its last sync time. Sign out or turn this off to clear the saved note.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    ),
    color: const Color(0xFFFFEDB9),
  );
}
