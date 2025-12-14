Map<String, double> computeNetBalances(
  List<Map<String, dynamic>> expenses, [
  Map<String, double>? settlements,
]) {
  final members = ['you', 'an', 'binh', 'chi'];
  final Map<String, double> net = {for (var m in members) m: 0.0};

  for (final e in expenses) {
    final amount = (e['amount'] is num) ? (e['amount'] as num).toDouble() : 0.0;
    final payerRaw = (e['payer'] ?? '').toString();
    final payer = payerRaw.toLowerCase();
    final splitRaw = (e['splitMode'] ?? '').toString();

    Map<String, double> shares = {for (var m in members) m: 0.0};

    if (splitRaw.contains('percent')) {
      final sd = e['splitDetails'];
      final pct = sd is Map
          ? (sd['percent'] is num
                ? (sd['percent'] as num).toDouble()
                : double.tryParse(sd['percent'].toString()) ?? 0.0)
          : 0.0;
      final pctMember = sd is Map
          ? (sd['memberId']?.toString().toLowerCase() ?? '')
          : '';
      final percentAmount = amount * (pct / 100.0);
      final others = members.where((m) => m != pctMember).toList();
      final perOther = others.isNotEmpty
          ? ((amount - percentAmount) / others.length)
          : 0.0;
      for (final m in members) {
        shares[m] = (m == pctMember) ? percentAmount : perOther;
      }
    } else if (splitRaw.contains('perPerson') || e['selectedMembers'] != null) {
      final selected = e['selectedMembers'] is List
          ? (e['selectedMembers'] as List)
                .map((x) => x.toString().toLowerCase())
                .where((x) => members.contains(x))
                .toList()
          : members;
      final sc = selected.isNotEmpty ? selected.length : 1;
      final perShare = amount / sc;
      for (final m in members) {
        shares[m] = selected.contains(m) ? perShare : 0.0;
      }
    } else {
      final per = amount / members.length;
      for (final m in members) {
        shares[m] = per;
      }
    }

    if (payer == 'you') {
      for (final m in members) {
        if (m == 'you') continue;
        net[m] = (net[m] ?? 0.0) + (shares[m] ?? 0.0);
      }
    } else {
      final youShare = shares['you'] ?? 0.0;
      final normalized = payer;
      net[normalized] = (net[normalized] ?? 0.0) - youShare;
    }
  }

  // Apply settlements
  if (settlements != null) {
    for (final entry in settlements.entries) {
      final id = entry.key;
      net[id] = (net[id] ?? 0.0) + entry.value;
    }
  }

  return net;
}
