import 'package:flutter/material.dart';
import 'garage_catalog.dart';
import 'store.dart';

/// Add this under the Garage illustration on the Decorate tab.
class GarageCustomizationPanel extends StatefulWidget {
  const GarageCustomizationPanel({super.key, required this.store});
  final AppStore store;

  @override
  State<GarageCustomizationPanel> createState() =>
      _GarageCustomizationPanelState();
}

class _GarageCustomizationPanelState extends State<GarageCustomizationPanel> {
  String group = 'paint';

  Future<void> _choose(GarageItem item) async {
    final store = widget.store;
    if (store.busy || store.garageEquipped[item.group] == item.id) return;
    if (!store.garageOwned.contains(item.id)) {
      final approve = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unlock ${item.label}?'),
          content: Text(
            '${item.detail}\n\nCost: ${item.price} shared hearts. '
            'You have ${store.coins} hearts. '
            'Once unlocked, both of you can use it for free.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: store.coins < item.price
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text('Unlock · ${item.price} hearts'),
            ),
          ],
        ),
      );
      if (approve != true || !mounted) return;
    }
    await store.run(() => store.equipGarageItem(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final choices = garageItems.where((i) => i.group == group).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Our dream car',
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 24,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        const Text(
          'Make our luxury sedan feel like us. Each upgrade belongs to both partners.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 5,
          children: [
            for (final entry in garageGroupLabels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: group == entry.key,
                onSelected: (_) => setState(() => group = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6DDE0)),
              ),
              child: Row(
                children: [
                  if (item.group == 'paint')
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: garagePaintColor(item.id),
                        border: Border.all(color: const Color(0xFFAAA0A8)),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 42,
                      child: Icon(Icons.auto_awesome_outlined,
                          color: Color(0xFFAD7488), size: 26),
                    ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 3),
                        Text(item.detail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF817580),
                            )),
                        const SizedBox(height: 3),
                        Text(
                          store.garageOwned.contains(item.id)
                              ? 'Owned · free to swap'
                              : '${item.price} hearts',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9B5572)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: store.busy ||
                            store.garageEquipped[item.group] == item.id
                        ? null
                        : () => _choose(item),
                    child: Text(
                      store.garageEquipped[item.group] == item.id
                          ? 'Equipped'
                          : store.garageOwned.contains(item.id)
                              ? 'Use'
                              : 'Unlock',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'Hearts are earned through your couple activities. No real-money purchases.',
          style: TextStyle(fontSize: 12, color: Color(0xFF817580)),
        ),
      ],
    );
  }
}
