/// Logic tính toán số dư nợ cho từng thành viên
Map<String, double> computeNetBalances(
  List<Map<String, dynamic>> expenses, [
  Map<String, double>? settlements,
  String? currentUserId,
  List<String>? memberIds,
]) {
  // Dùng memberIds từ database, fallback về default nếu không có
  final members = memberIds ?? ['you', 'an', 'binh', 'chi'];
  final currentUser = currentUserId ?? 'you';

  final Map<String, double> net = {for (var m in members) m: 0.0};

  for (final e in expenses) {
    // Bỏ qua những expense đã thanh toán (settled - dùng để compatibility)
    if (e['settled'] == true) continue;

    final totalAmount = (e['totalAmount'] is num)
        ? (e['totalAmount'] as num).toDouble()
        : (e['amount'] is num)
        ? (e['amount'] as num).toDouble()
        : 0.0;
    final payerId = (e['payer'] ?? e['paidBy'] ?? '').toString();

    // Lấy participants từ expense
    final participantsData = e['participants'];
    List<String> participants = [];

    if (participantsData is Map) {
      participants = participantsData.keys
          .where((key) => participantsData[key] == true)
          .map((key) => key.toString())
          .toList();
    } else if (participantsData is List) {
      participants = participantsData.map((x) => x.toString()).toList();
    }
    if (participants.isEmpty) {
      participants = members;
    }

    // Tính số tiền từng người phải chịu dựa trên splitMode
    final splitMode = e['splitMode']?.toString() ?? 'SplitMode.equal';
    final splitDetails = e['splitDetails'] as Map<String, dynamic>?;
    final Map<String, dynamic> settledPairs =
        (e['settledPairs'] as Map<String, dynamic>?) ?? {};
    Map<String, double> splitAmounts = {};

    if (splitMode.contains('percent')) {
      final percent = (splitDetails?['percent'] ?? 0) as num;
      final percentMember = splitDetails?['memberId']?.toString();
      if (percentMember != null) {
        final pctAmount = totalAmount * percent / 100;
        splitAmounts[percentMember] = pctAmount;
        final others = participants.where((m) => m != percentMember).toList();
        if (others.isNotEmpty) {
          final remain = totalAmount - pctAmount;
          final per = remain / others.length;
          for (final m in others) {
            splitAmounts[m] = per;
          }
        }
      }
    } else if (splitMode.contains('perPerson')) {
      final selected = e['selectedMembers'] is List
          ? (e['selectedMembers'] as List).map((x) => x.toString()).toList()
          : <String>[];
      final use = selected.isNotEmpty ? selected : participants;
      if (use.isNotEmpty) {
        final per = totalAmount / use.length;
        for (final m in use) {
          splitAmounts[m] = per;
        }
      }
    } else {
      // Chia đều
      final use = participants.isNotEmpty ? participants : members;
      if (use.isNotEmpty) {
        final per = totalAmount / use.length;
        for (final m in use) {
          splitAmounts[m] = per;
        }
      }
    }

    // Cập nhật balances
    for (final entry in splitAmounts.entries) {
      final memberId = entry.key;
      final perPerson = entry.value;
      if (memberId == payerId) continue; // người trả không nợ chính mình

      // Kiểm tra xem cặp này đã settled chưa (check cả 2 chiều)
      final pairKey1 = '$payerId:$memberId';
      final pairKey2 = '$memberId:$payerId';
      if (settledPairs.containsKey(pairKey1) ||
          settledPairs.containsKey(pairKey2)) {
        continue; // Bỏ qua cặp đã thanh toán
      }

      // Dùng sorted key để match logic lưu ở frontend
      final ids = [payerId, memberId];
      ids.sort();
      final sortedPairKey = '${ids[0]}:${ids[1]}';
      if (settledPairs.containsKey(sortedPairKey)) {
        continue;
      }

      if (memberId == currentUser) {
        // currentUser nợ payer
        net[payerId] = (net[payerId] ?? 0.0) - perPerson;
      } else if (payerId == currentUser) {
        // người khác nợ currentUser
        net[memberId] = (net[memberId] ?? 0.0) + perPerson;
      }
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
