import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../store.dart';
import 'same_thought_logic.dart';

/// A private live match for the two accounts paired in the same Little Us home.
/// No answer/score is trusted from the client; RPC responses are authoritative.
class SameThoughtScreen extends StatefulWidget {
  const SameThoughtScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<SameThoughtScreen> createState() => _SameThoughtScreenState();
}

class _SameThoughtScreenState extends State<SameThoughtScreen>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF443747);
  static const _muted = Color(0xFF817580);
  static const _coral = Color(0xFFC75E68);
  static const _cream = Color(0xFFFFFAF4);
  static const _lilac = Color(0xFFEDE3F6);

  final _word = TextEditingController();
  Timer? _poller;
  Timer? _clock;
  RealtimeChannel? _channel;
  String? _matchId;
  SameThoughtSnapshot? _snapshot;
  Duration _serverOffset = Duration.zero;
  String? _error;
  bool _busy = false;
  bool _fetching = false;
  bool _disposed = false;
  int _lastRound = 0;

  SupabaseClient get _client => widget.store.client!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && _snapshot?.phase == 'answer') setState(() {});
    });
    unawaited(_enter());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _enter() async {
    if (widget.store.demo ||
        widget.store.client == null ||
        !widget.store.paired) {
      if (mounted) {
        setState(() => _error =
            'Same Thought needs two paired, signed-in accounts online.');
      }
      return;
    }
    setState(() {
      _error = null;
      _snapshot = null;
      _busy = true;
    });
    try {
      final id = (await _client.rpc('st_join_or_create')).toString();
      if (!mounted) return;
      await _clearChannel();
      _matchId = id;
      _lastRound = 0;
      _word.clear();
      _channel = _client.channel(
        'same-thought:$id',
        opts: const RealtimeChannelConfig(private: true),
      );
      _channel!
          .onBroadcast(event: 'changed', callback: (_) => unawaited(_refresh()))
          .subscribe();
      _poller?.cancel();
      _poller = Timer.periodic(
        const Duration(milliseconds: 1300),
        (_) => unawaited(_refresh()),
      );
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearChannel() async {
    _poller?.cancel();
    _poller = null;
    final old = _channel;
    _channel = null;
    if (old != null) {
      await _client.removeChannel(old);
    }
  }

  Future<void> _refresh() async {
    final id = _matchId;
    if (id == null || _fetching || _disposed) return;
    _fetching = true;
    try {
      final result = await _client.rpc('st_state', params: {'p_match': id});
      if (!mounted || id != _matchId) return;
      final next =
          SameThoughtSnapshot(Map<String, dynamic>.from(result as Map));
      final serverNow = next.serverNow;
      if (serverNow != null)
        _serverOffset = serverNow.difference(DateTime.now().toUtc());
      if (next.round != _lastRound && next.phase == 'answer') {
        _word.clear();
        _lastRound = next.round;
      }
      setState(() {
        _snapshot = next;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      _fetching = false;
    }
  }

  Future<void> _wakePartner() async {
    try {
      await _channel?.sendBroadcastMessage(
        event: 'changed',
        payload: <String, dynamic>{'refresh': true},
      );
    } catch (_) {
      // The timed state poll is the fallback when WebSocket is unavailable.
    }
  }

  Future<void> _perform(String rpc, Map<String, dynamic> params) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _client.rpc(rpc, params: params);
      await _wakePartner();
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) return error.message;
    return 'Connection problem. Check your internet and retry. ($error)';
  }

  Future<void> _confirmCancel() async {
    if (_matchId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this match?'),
        content: const Text(
            'This ends the live match for both partners. No hearts are affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End match')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform('st_cancel', {'p_match': _matchId});
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    _clock?.cancel();
    _word.dispose();
    final ch = _channel;
    if (ch != null) unawaited(_client.removeChannel(ch));
    super.dispose();
  }

  Widget _section({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: child,
      );

  Widget _title(String value) => Text(value,
      style: const TextStyle(
          color: _ink, fontSize: 22, fontWeight: FontWeight.w800));

  Widget _lobby(SameThoughtSnapshot s) => _section(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _title('Choose our categories'),
          const SizedBox(height: 6),
          const Text(
              'Each of you chooses one category. The five rounds alternate between your choices.',
              style: TextStyle(color: _muted)),
          const SizedBox(height: 18),
          Text('Your choice: ${s.myCategory ?? 'Not chosen'}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('category-${s.myCategory}'),
            value: s.myCategory,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'My category', border: OutlineInputBorder()),
            items: sameThoughtCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null && value != s.myCategory) {
                      unawaited(_perform('st_choose_category',
                          {'p_match': _matchId, 'p_category': value}));
                    }
                  },
          ),
          const SizedBox(height: 15),
          _line('Your partner chose', s.partnerCategory ?? 'Waiting…'),
          _line('Your partner',
              s.partnerOnline ? 'Online' : 'Not in the lobby yet'),
          _line('Ready',
              '${s.myReady ? 'You ✓' : 'You —'}  ·  ${s.partnerReady ? 'Partner ✓' : 'Partner —'}'),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _busy || s.myCategory == null || s.partnerCategory == null
                        ? null
                        : () => unawaited(_perform('st_set_ready',
                            {'p_match': _matchId, 'p_ready': !s.myReady})),
                icon: Icon(s.myReady
                    ? Icons.hourglass_top
                    : Icons.check_circle_outline),
                label: Text(s.myReady ? 'Cancel ready' : 'I’m ready'),
              )),
          if (s.myReady) ...[
            const SizedBox(height: 12),
            const Text(
                'The match begins when both partners are ready and online.',
                style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ]),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: _muted))),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _playing(SameThoughtSnapshot s) {
    final seconds =
        (s.remainingMs(localNow: DateTime.now(), serverOffset: _serverOffset) /
                1000)
            .ceil();
    final answering = s.phase == 'answer';
    return Column(children: [
      _section(
          child: Column(children: [
        Text('ROUND ${s.round} OF 5',
            style: const TextStyle(color: _coral, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(s.category ?? '',
            style: const TextStyle(
                color: _ink, fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 5),
        Text(s.letter ?? '–',
            style: const TextStyle(
                color: _coral, fontSize: 76, fontWeight: FontWeight.w900)),
        Text(answering ? '$seconds seconds left' : 'Time to reveal!',
            style: const TextStyle(
                fontSize: 17, color: _ink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: answering ? (seconds / 15).clamp(0.0, 1.0) : 1.0,
          backgroundColor: _lilac,
          color: _coral,
          minHeight: 7,
          borderRadius: BorderRadius.circular(7),
        ),
      ])),
      const SizedBox(height: 15),
      _section(
          child: answering
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      _title(s.mySubmitted
                          ? 'Your word is locked!'
                          : 'What’s your word?'),
                      const SizedBox(height: 8),
                      const Text('Your answers are secret until the reveal.',
                          style: TextStyle(color: _muted)),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _word,
                        enabled: !s.mySubmitted && !_busy && seconds > 0,
                        maxLength: 32,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            hintText: 'Type your guess',
                            border: OutlineInputBorder()),
                        onSubmitted: (_) => _submit(s),
                      ),
                      FilledButton(
                        onPressed: !s.mySubmitted && !_busy && seconds > 0
                            ? () => _submit(s)
                            : null,
                        child: Text(s.mySubmitted
                            ? 'Answer submitted ✓'
                            : 'Lock answer'),
                      ),
                      const SizedBox(height: 10),
                      _line('Your partner',
                          s.partnerSubmitted ? 'Submitted ✓' : 'Thinking…'),
                    ])
              : Column(children: [
                  _title(s.matched == true
                      ? 'Same thought! ✨'
                      : 'Different minds, same team 💗'),
                  const SizedBox(height: 14),
                  _line('Your word', s.myAnswer ?? '(No answer)'),
                  _line('Partner’s word', s.partnerAnswer ?? '(No answer)'),
                  const SizedBox(height: 8),
                  Text(
                      s.matched == true
                          ? '+1 team point!'
                          : 'No point this round',
                      style: const TextStyle(
                          color: _coral, fontWeight: FontWeight.w800)),
                ])),
    ]);
  }

  void _submit(SameThoughtSnapshot s) {
    final guess = _word.text.trim();
    if (guess.isEmpty || s.mySubmitted || _busy) return;
    unawaited(_perform('st_submit',
        {'p_match': _matchId, 'p_round': s.round, 'p_word': guess}));
  }

  Widget _finished(SameThoughtSnapshot s) => _section(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              s.status == 'cancelled' ? 'Match ended' : 'Our minds in sync! 💗',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _ink, fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('${s.score} / 5',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _coral, fontSize: 46, fontWeight: FontWeight.w900)),
          const Text('Shared matching points · No hearts or streaks',
              textAlign: TextAlign.center, style: TextStyle(color: _muted)),
          const SizedBox(height: 18),
          ...s.recap.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    r['matched'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _coral),
                title:
                    Text('${r['number']}. ${r['category']} · ${r['letter']}'),
                subtitle: Text('${r['you'] ?? '—'}  /  ${r['partner'] ?? '—'}'),
                trailing: Text(r['matched'] == true ? '+1' : '0'),
              )),
          const SizedBox(height: 15),
          FilledButton.icon(
              onPressed: _busy ? null : () => unawaited(_enter()),
              icon: const Icon(Icons.replay),
              label: const Text('Play again')),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Same Thought'),
        backgroundColor: _cream,
        actions: [
          if (s != null && s.status != 'finished' && s.status != 'cancelled')
            IconButton(
                onPressed: _confirmCancel,
                tooltip: 'End match',
                icon: const Icon(Icons.close_rounded)),
        ],
      ),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('One letter. Two minds. One team.',
              textAlign: TextAlign.center, style: TextStyle(color: _muted)),
          const SizedBox(height: 15),
          if (_error != null) ...[
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFECEA),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(_error!,
                      style: const TextStyle(color: Color(0xFF9E303A))),
                  if (_matchId == null)
                    TextButton(onPressed: _enter, child: const Text('Retry')),
                ])),
            const SizedBox(height: 15),
          ],
          if (s != null) ...[
            if (s.status == 'lobby')
              _lobby(s)
            else if (s.status == 'active')
              _playing(s)
            else
              _finished(s),
            const SizedBox(height: 16),
            if (s.status == 'active') _line('Team score', '${s.score} / 5'),
          ] else if (_error == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(35),
                child: CircularProgressIndicator(),
              ),
            ),
        ]),
      )),
    );
  }
}
