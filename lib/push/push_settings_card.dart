import 'package:flutter/material.dart';
import '../store.dart';
import 'push_manager.dart';

class PushSettingsCard extends StatefulWidget {
  const PushSettingsCard({super.key, required this.store});
  final AppStore store;

  @override
  State<PushSettingsCard> createState() => _PushSettingsCardState();
}

class _PushSettingsCardState extends State<PushSettingsCard> {
  bool busy = false;

  Future<void> change(bool next) async {
    final manager = PushManager.instance;
    if (manager == null) return;
    setState(() => busy = true);
    try {
      await manager.setEnabled(next);
      if (mounted && next) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications enabled. iOS delivery may need APNs setup.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = PushManager.instance;
    if (widget.store.demo) return const SizedBox.shrink();
    if (manager == null) {
      return const ListTile(
        leading: Icon(Icons.notifications_off_outlined),
        title: Text('Partner notifications'),
        subtitle: Text('Finish Firebase setup to enable notifications on this device.'),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: manager.enabled,
      builder: (context, value, _) => SwitchListTile.adaptive(
        secondary: const Icon(Icons.notifications_active_outlined),
        title: const Text('Partner notifications'),
        subtitle: const Text(
          'New fridge notes, Same Thought invites, and doodle updates. '
          'Only generic alerts; private content stays in the app. '
          'This setting applies to this device.',
        ),
        value: value,
        onChanged: busy ? null : change,
      ),
    );
  }
}
