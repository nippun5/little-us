import 'dart:async';
import 'package:flutter/material.dart';
import '../../store.dart';
import 'doodle_canvas.dart';
import 'doodle_model.dart';
import 'doodle_repository.dart';

const _ink = Color(0xFF443747);
const _pink = Color(0xFFC75E68);
const _muted = Color(0xFF817580);
const _mint = Color(0xFFE2EFE5);
const _lilac = Color(0xFFEDE3F6);
const _cream = Color(0xFFFFFAF4);

class FinishMyDoodleScreen extends StatefulWidget {
  const FinishMyDoodleScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<FinishMyDoodleScreen> createState() => _FinishMyDoodleScreenState();
}

class _FinishMyDoodleScreenState extends State<FinishMyDoodleScreen>
    with WidgetsBindingObserver {
  late final DoodleRepository _repo;
  Timer? _refreshTimer;
  List<CoupleDoodle> _items = [];
  bool _busy = false, _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = DoodleRepository(widget.store);
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _load(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_busy) return;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final items = await _repo.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([CoupleDoodle? item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _DoodleEditor(repo: _repo, existing: item),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(CoupleDoodle item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this doodle?'),
        content:
            const Text('This removes it for both of you and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.delete(item.id);
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(_friendlyError(e));
    }
  }

  Future<void> _demoFinish(CoupleDoodle item) async {
    setState(() => _busy = true);
    try {
      await _repo.simulateDemoPartner(item.id);
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(_friendlyError(e));
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );

  @override
  Widget build(BuildContext context) {
    final open = _items.where((e) => !e.isFinished).toList();
    final finished = _items.where((e) => e.isFinished).toList();
    final canStart = open.isEmpty && _items.length < 40;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text('Finish My Doodle'),
        actions: [
          IconButton(
            tooltip: 'Refresh doodles',
            onPressed: _busy ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text('You start it. Your person finishes it.',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            const Text(
                'Draw something silly, pass it along, and see what it becomes. No timers, scores, or hearts.',
                style: TextStyle(color: _muted, height: 1.5)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed:
                  canStart && !_busy && !_loading ? () => _openEditor() : null,
              icon: const Icon(Icons.draw_outlined),
              label: const Text('Start a new doodle'),
            ),
            if (!canStart)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Only one unfinished doodle at a time. Finish or remove it to start another.',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ),
            if (widget.store.demo)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                    'Demo mode uses a simulated partner. Real accounts share doodles privately through Supabase.',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: _pink)),
              ),
            if (!_loading) ...[
              const SizedBox(height: 24),
              _section('In progress', Icons.auto_awesome_outlined),
              if (open.isEmpty)
                _empty('No doodle in progress. Start one for your person!'),
              for (final doodle in open)
                _doodleCard(
                  doodle,
                  title: doodle.canFinish
                      ? 'Your turn to finish!'
                      : 'Waiting for your person',
                  actionLabel: doodle.canFinish ? 'Finish this doodle' : null,
                  action: doodle.canFinish ? () => _openEditor(doodle) : null,
                ),
              const SizedBox(height: 24),
              _section('Our finished doodles', Icons.favorite_border_rounded),
              if (finished.isEmpty)
                _empty('Your completed creations will appear here.'),
              for (final doodle in finished)
                _doodleCard(
                  doodle,
                  title: 'Made together',
                  actionLabel: 'View and replay',
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => _DoodleReplay(entry: doodle)),
                  ),
                ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: _pink, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(message, style: const TextStyle(color: _muted)),
      );

  Widget _doodleCard(
    CoupleDoodle doodle, {
    required String title,
    required String? actionLabel,
    required VoidCallback? action,
  }) =>
      Card(
        margin: const EdgeInsets.only(top: 12),
        color: doodle.isFinished ? _lilac : _mint,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, color: _ink, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(doodle.prompt, style: const TextStyle(color: _muted)),
              const SizedBox(height: 8),
              Text('Started by ${doodle.starterName}',
                  style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CustomPaint(
                        painter: DoodlePainter(
                            original: doodle.original,
                            additions: doodle.addition),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (action != null && actionLabel != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : action,
                    child: Text(actionLabel),
                  ),
                ),
              if (widget.store.demo && !doodle.isFinished)
                TextButton.icon(
                  onPressed: _busy ? null : () => _demoFinish(doodle),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Demo: simulate partner finishing'),
                ),
              if (doodle.isFinished || doodle.isMine)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => _delete(doodle),
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: const Text('Remove'),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _DoodleEditor extends StatefulWidget {
  const _DoodleEditor({required this.repo, this.existing});
  final DoodleRepository repo;
  final CoupleDoodle? existing;
  @override
  State<_DoodleEditor> createState() => _DoodleEditorState();
}

class _DoodleEditorState extends State<_DoodleEditor> {
  final DoodleController _controller = DoodleController();
  String _prompt = DoodleRules.prompts.first;
  bool _saving = false;
  bool _painting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strokes = _controller.drawing.strokes;
    final message = DoodleRules.validate(strokes);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.repo.start(_prompt, strokes);
      } else {
        await widget.repo.finish(widget.existing!.id, strokes);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinishing = widget.existing != null;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: Text(isFinishing ? 'Finish their doodle' : 'Start a doodle'),
      ),
      body: SafeArea(
        child: ListView(
          physics: _painting
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (!isFinishing)
              DropdownButtonFormField<String>(
                value: _prompt,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Drawing prompt'),
                items: [
                  for (final p in DoodleRules.prompts)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _prompt = value);
                      },
              )
            else ...[
              Text(widget.existing!.prompt,
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              const Text(
                  'Their drawing is locked. Add your own lines to complete it!',
                  style: TextStyle(color: _muted)),
            ],
            const SizedBox(height: 14),
            DoodleCanvas(
              controller: _controller,
              base: widget.existing?.original ?? const [],
              onPaintingChanged: (painting) {
                if (mounted && _painting != painting) {
                  setState(() => _painting = painting);
                }
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 8,
              children: [
                for (final color in DoodleRules.colors)
                  InkWell(
                    onTap: () => _controller.setColor(color),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) |
                            0xFF000000),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _controller.drawing.color == color
                              ? _ink
                              : Colors.white,
                          width: _controller.drawing.color == color ? 3 : 2,
                        ),
                      ),
                      child: _controller.drawing.color == color
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pen', style: TextStyle(color: _muted)),
                const SizedBox(width: 12),
                for (final width in DoodleRules.widths)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('$width'),
                      selected: _controller.drawing.width == width,
                      onSelected: (_) => _controller.setWidth(width),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Undo last stroke',
                  onPressed: _saving ? null : _controller.undo,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: 'Clear your strokes',
                  onPressed: _saving ? null : _controller.clear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            Text(
                '${DoodleRules.maxPoints - _controller.drawing.pointCount} drawing points left',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(
                  isFinishing ? 'Finish and reveal' : 'Send to your person'),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _DoodleReplay extends StatefulWidget {
  const _DoodleReplay({required this.entry});
  final CoupleDoodle entry;
  @override
  State<_DoodleReplay> createState() => _DoodleReplayState();
}

class _DoodleReplayState extends State<_DoodleReplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
    value: 1,
  );

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
            backgroundColor: _cream,
            title: const Text('Our little masterpiece')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.entry.prompt,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 22, color: _ink)),
              const SizedBox(height: 6),
              Text('Started by ${widget.entry.starterName} · Finished together',
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: DoodlePainter(
                      original: widget.entry.original,
                      additions: widget.entry.addition,
                      progress: _animation,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _animation.forward(from: 0),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Replay our drawing'),
              ),
              const SizedBox(height: 12),
              const Text('Two imaginations. One doodle. 💗',
                  textAlign: TextAlign.center, style: TextStyle(color: _muted)),
            ],
          ),
        ),
      );
}

String _friendlyError(Object error) {
  if (error is FormatException) return error.message;
  // Supabase exceptions expose a human-readable message in toString().
  final message = error.toString();
  return message.length > 220 ? '${message.substring(0, 220)}…' : message;
}
