import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _houseId;

  FinanceService({String? houseId}) : _houseId = houseId;

  // Collections (scoped under houses/{houseId} when provided)
  CollectionReference<Map<String, dynamic>> get _expensesCol => _houseId == null
      ? _db.collection('expenses')
      : _db.collection('houses').doc(_houseId).collection('expenses');

  CollectionReference<Map<String, dynamic>> get _settlementsCol =>
      _houseId == null
      ? _db.collection('finance_settlements')
      : _db
            .collection('houses')
            .doc(_houseId)
            .collection('finance_settlements');

  CollectionReference<Map<String, dynamic>> get _balancesCol => _houseId == null
      ? _db.collection('balances')
      : _db.collection('houses').doc(_houseId).collection('balances');

  CollectionReference<Map<String, dynamic>> get _paymentLogsCol =>
      _houseId == null
      ? _db.collection('payment_logs')
      : _db.collection('houses').doc(_houseId).collection('payment_logs');

  // Stream all expenses ordered by date desc
  Stream<List<Map<String, dynamic>>> expensesStream() {
    return _expensesCol
        .orderBy('createdAt', descending: true)
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
  // Đọc từ balances/{userId}/debts/{toUserId}
  Stream<Map<String, double>> balancesStreamForUser(String userId) {
    if (_houseId == null) return Stream.value({});

    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('balances')
        .doc(userId)
        .collection('debts')
        .snapshots()
        .map((snap) {
          final Map<String, double> result = {};
          for (final doc in snap.docs) {
            final data = doc.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final status = data['status'] as String? ?? 'unpaid';

            // Chỉ tính nợ chưa thanh toán
            if (status == 'unpaid' || status == 'paying') {
              result[doc.id] = amount; // doc.id là toUserId
            }
          }
          return result;
        });
  }

  // Stream tất cả balances của tất cả members
  Stream<Map<String, Map<String, double>>> allBalancesStream(
    List<String> memberIds,
  ) {
    if (_houseId == null || memberIds.isEmpty) return Stream.value({});

    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('balances')
        .snapshots()
        .map((snap) {
          final Map<String, Map<String, double>> result = {};

          for (final userDoc in snap.docs) {
            final userId = userDoc.id;
            result[userId] = {};
          }

          return result;
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
    out['id'] = d.id; // keep Firestore id for detail lookups
    final t = data['createdAt'];
    if (t is Timestamp) {
      out['date'] = t.toDate();
    }
    return out;
  }

  // ============ BALANCES METHODS ============

  /// Stream all balances
  Stream<List<Map<String, dynamic>>> balancesListStream() {
    return _balancesCol
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            final out = Map<String, dynamic>.from(data);
            out['id'] = doc.id;
            return out;
          }).toList(),
        );
  }

  /// Stream unpaid balances only
  Stream<List<Map<String, dynamic>>> unpaidBalancesStream() {
    return _balancesCol
        .where('status', isEqualTo: 'unpaid')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            final out = Map<String, dynamic>.from(data);
            out['id'] = doc.id;
            return out;
          }).toList(),
        );
  }

  /// Get total debt for a user
  Future<double> getTotalDebt(String userId) async {
    try {
      final snap = await _balancesCol
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'unpaid')
          .get();

      double total = 0;
      for (final doc in snap.docs) {
        final amount = doc.data()['amount'];
        if (amount is num) {
          total += amount.toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get total credit for a user
  Future<double> getTotalCredit(String userId) async {
    try {
      final snap = await _balancesCol
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'unpaid')
          .get();

      double total = 0;
      for (final doc in snap.docs) {
        final amount = doc.data()['amount'];
        if (amount is num) {
          total += amount.toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // ============ PAYMENT LOGS METHODS ============

  /// Stream payment logs (lịch sử chốt sổ)
  Stream<List<Map<String, dynamic>>> paymentLogsStream() {
    return _paymentLogsCol
        .orderBy('confirmedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            final out = Map<String, dynamic>.from(data);
            out['id'] = doc.id;
            return out;
          }).toList(),
        );
  }
}
