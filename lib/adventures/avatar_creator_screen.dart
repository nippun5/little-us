import 'package:flutter/material.dart';
import '../store.dart';
import 'avatar_model.dart';
import 'avatar_preview.dart';
import 'avatar_repository.dart';

/// Milestone 1. Each signed-in partner can edit only their own avatar.
/// The partner preview is loaded read-only from the same home.
class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  static const _cream = Color(0xFFFFFAF4);
  static const _ink = Color(0xFF443747);
  static const _accent = Color(0xFFC75E68);
  static const _lilac = Color(0xFFEDE3F6);

  late final AvatarRepository _repository;
  CoupleAvatar _draft = const CoupleAvatar();
  CoupleAvatar _saved = const CoupleAvatar();
  CoupleAvatar _partner = CoupleAvatar.partnerPlaceholder;
  bool _partnerSaved = false;
  bool _mineSaved = false;
  bool _loaded = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _dirty => _draft != _saved || (!_mineSaved && _loaded);

  @override
  void initState() {
    super.initState();
    _repository = AvatarRepository(widget.store);
    _load();
  }

  Future<void> _load() async {
    if (_saving) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pair = await _repository.load();
      if (!mounted) return;
      setState(() {
        _draft = pair.mine;
        _saved = pair.mine;
        _partner = pair.partner;
        _partnerSaved = pair.partnerSaved;
        _mineSaved = pair.mineSaved;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loaded = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
              'Refreshing reloads both avatars and discards edits you have not saved.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard and refresh')),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    await _load();
  }

  void _pick(String category, String value) {
    setState(() => _draft = _draft.withOption(category, value));
  }

  Future<void> _save() async {
    if (_saving || !_loaded || !_dirty) return;
    final value = _draft;
    setState(() => _saving = true);
    try {
      await _repository.saveMine(value);
      if (!mounted) return;
      setState(() {
        _saved = value;
        _mineSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Your avatar is saved! Your partner can see it after refreshing.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save avatar: $error'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _previewCard(String title, String subtitle, CoupleAvatar avatar) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 14, 9, 12),
          decoration: BoxDecoration(
            color: _lilac,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                    color: Color(0xFF766976),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: AvatarPreview(avatar: avatar),
              ),
            ],
          ),
        ),
      );

  Widget _option(String category, String id, String selected) {
    final chosen = id == selected;
    final color = (category == 'skin_tone' || category == 'hair_color')
        ? AvatarCatalog.swatches[id]
        : null;
    return ChoiceChip(
      key: ValueKey('avatar_${category}_$id'),
      label: Text(AvatarCatalog.label(id)),
      selected: chosen,
      onSelected: (_) => _pick(category, id),
      selectedColor: const Color(0xFFF2D6DC),
      showCheckmark: false,
      side: BorderSide(color: chosen ? _accent : const Color(0xFFE3D9E0)),
      avatar: color == null
          ? null
          : CircleAvatar(
              backgroundColor: color,
              radius: 12,
            ),
      labelStyle: TextStyle(
        color: _ink,
        fontWeight: chosen ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }

  Widget _category(String key, List<String> choices) {
    final selected = _draft.toJson()[key]!;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AvatarCatalog.label(key),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink,
              )),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in choices) _option(key, option, selected)
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text('Our avatars'),
        actions: [
          IconButton(
            tooltip: 'Refresh partner avatar',
            onPressed: _loading || _saving ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_loaded
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error ?? 'Unable to load avatars.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 630),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: [
                      const Text('The two of us, anywhere.',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                          )),
                      const SizedBox(height: 6),
                      const Text(
                        'Create your own character. Your person creates theirs on their phone.',
                        style: TextStyle(color: Color(0xFF766976)),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _previewCard(
                              widget.store.myName,
                              _mineSaved
                                  ? 'Your saved look'
                                  : 'Ready to customize',
                              _draft),
                          const SizedBox(width: 10),
                          _previewCard(
                              widget.store.partner,
                              widget.store.demo
                                  ? 'Simulated partner (demo)'
                                  : _partnerSaved
                                      ? 'Partner’s saved look'
                                      : 'Not customized yet',
                              _partner),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFE6),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'All starter appearance options are free. Outfits and cosmetics can use hearts later, once the shop system is added.',
                          style: TextStyle(fontSize: 12, color: _ink),
                        ),
                      ),
                      for (final entry in AvatarCatalog.options.entries)
                        _category(entry.key, entry.value),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _dirty
                            ? () => setState(() => _draft = _saved)
                            : null,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Undo unsaved changes'),
                      ),
                    ],
                  ),
                )),
      bottomNavigationBar: !_loaded || _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saving || !_dirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.favorite_rounded),
                label: Text(_saving
                    ? 'Saving…'
                    : _dirty
                        ? 'Save my avatar'
                        : 'Saved'),
              ),
            ),
    );
  }
}
