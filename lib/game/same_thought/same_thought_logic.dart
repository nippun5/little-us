/// Local, display-only helpers. The database alone decides whether a guess is
/// accepted and whether a round scores a point.
const sameThoughtCategories = <String>[
  'Animals',
  'Food',
  'Countries',
  'Colors',
  'Jobs',
];

String normalizeSameThoughtWord(String input) =>
    input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

bool localSameThoughtMatch(String? a, String? b) {
  if (a == null || b == null) return false;
  final first = normalizeSameThoughtWord(a);
  return first.isNotEmpty && first == normalizeSameThoughtWord(b);
}

class SameThoughtSnapshot {
  SameThoughtSnapshot(this.data);
  final Map<String, dynamic> data;

  String get status => data['status']?.toString() ?? 'lobby';
  String get phase => data['phase']?.toString() ?? 'lobby';
  int get round => (data['round_no'] as num?)?.toInt() ?? 0;
  int get score => (data['score'] as num?)?.toInt() ?? 0;
  String? get category => data['category'] as String?;
  String? get letter => data['letter'] as String?;
  String? get myCategory => data['my_category'] as String?;
  String? get partnerCategory => data['partner_category'] as String?;
  bool get myReady => data['my_ready'] == true;
  bool get partnerReady => data['partner_ready'] == true;
  bool get partnerOnline => data['partner_online'] == true;
  bool get mySubmitted => data['my_submitted'] == true;
  bool get partnerSubmitted => data['partner_submitted'] == true;
  bool? get matched => data['matched'] as bool?;
  String? get myAnswer => data['my_answer'] as String?;
  String? get partnerAnswer => data['partner_answer'] as String?;
  DateTime? get deadline =>
      DateTime.tryParse(data['deadline']?.toString() ?? '')?.toUtc();
  DateTime? get serverNow =>
      DateTime.tryParse(data['server_now']?.toString() ?? '')?.toUtc();

  List<Map<String, dynamic>> get recap =>
      (data['recap'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);

  int remainingMs(
      {required DateTime localNow, Duration serverOffset = Duration.zero}) {
    final end = deadline;
    if (end == null) return 0;
    final remaining =
        end.difference(localNow.toUtc().add(serverOffset)).inMilliseconds;
    return remaining > 0 ? remaining : 0;
  }
}
