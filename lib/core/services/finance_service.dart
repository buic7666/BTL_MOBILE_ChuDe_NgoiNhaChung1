import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _houseId;

  FinanceService({String? houseId}) : _houseId = houseId;

  // Collections (scoped under houses/{houseId} when provided)
  CollectionReference<Map<String, dynamic>> get _expensesCol => _houseId == null
      ? _db.collection('finance_expenses')
      : _db.collection('houses').doc(_houseId).collection('finance_expenses');
  CollectionReference<Map<String, dynamic>> get _settlementsCol =>
      _houseId == null
      ? _db.collection('finance_settlements')
      : _db
            .collection('houses')
            .doc(_houseId)
            .collection('finance_settlements');

  // Stream all expenses ordered by date desc
  Stream<List<Map<String, dynamic>>> expensesStream() {
    return _expensesCol
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_mapFromDoc).toList());
  }

  // Add an expense document
  Future<void> addExpense(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final date = payload['date'];
    if (date is DateTime) {
      payload['date'] = Timestamp.fromDate(date);
    }
    await _expensesCol.add(payload);
  }

  // Stream settlements aggregated per memberId
  Stream<Map<String, double>> settlementsStream() {
    return _settlementsCol.snapshots().map((snap) {
      final Map<String, double> agg = {};
      for (final d in snap.docs) {
        final data = d.data();
        final id = (data['memberId'] ?? '').toString();
        final deltaRaw = data['delta'];
        final delta = deltaRaw is num ? deltaRaw.toDouble() : 0.0;
        if (id.isEmpty) continue;
        agg[id] = (agg[id] ?? 0.0) + delta;
      }
      return agg;
    });
  }

  // Stream materialized balances from Cloud Functions
  Stream<Map<String, double>?> balancesStream() {
    final doc = (_houseId == null)
        ? _db
              .collection('finance_balances')
              .doc('summary') // fallback (unlikely)
        : _db
              .collection('houses')
              .doc(_houseId)
              .collection('finance_balances')
              .doc('summary');
    return doc.snapshots().map((d) {
      if (!d.exists) return null;
      final data = d.data() as Map<String, dynamic>;
      final net = data['net'] as Map<String, dynamic>?;
      if (net == null) return null;
      return net.map((k, v) => MapEntry(k, (v is num) ? v.toDouble() : 0.0));
    });
  }

  // Record a settlement entry
  Future<void> addSettlement({
    required String memberId,
    required double delta,
  }) {
    return _settlementsCol.add({
      'memberId': memberId,
      'delta': delta,
      'date': Timestamp.now(),
    });
  }

  // Helper to map Firestore doc to UI Map
  Map<String, dynamic> _mapFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data();
    final out = Map<String, dynamic>.from(data);
    final t = data['date'];
    if (t is Timestamp) {
      out['date'] = t.toDate();
    }
    return out;
  }
}
