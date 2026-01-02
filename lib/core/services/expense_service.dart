import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _houseId;

  ExpenseService({required String houseId}) : _houseId = houseId;

  // ============ STREAM EXPENSES ============

  /// Stream tất cả chi phí của house
  Stream<List<Map<String, dynamic>>> expensesStream() {
    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'createdBy': data['createdBy'],
              'paidBy': data['paidBy'],
              'totalAmount': data['totalAmount'],
              'splitAmount': data['splitAmount'],
              'participants': data['participants'],
              'createdAt': data['createdAt'],
            };
          }).toList(),
        );
  }

  // ============ ADD EXPENSE ============

  /// Frontend gửi:
  /// {
  ///   "paidBy": "user_A",
  ///   "totalAmount": 150000,
  ///   "title": "Ăn trưa nhóm",
  ///   "participants": { "user_A": true, "user_B": true, "user_C": true },
  ///   "date": DateTime
  /// }
  ///
  /// Cloud Function sẽ:
  /// 1. Tính splitAmount = totalAmount / numberOfParticipants
  /// 2. Ghi expense
  /// 3. Update balances (AI NỢ AI)
  Future<void> addExpense({
    required String paidBy,
    required double totalAmount,
    required Map<String, bool> participants,
    String title = '',
    DateTime? date,
    String? createdBy,
  }) async {
    try {
      // Ghi expense request vào Firestore
      // Cloud Function listener sẽ xử lý tự động
      await _db
          .collection('houses')
          .doc(_houseId)
          .collection('expense_requests')
          .add({
            'createdBy': createdBy ?? 'unknown',
            'paidBy': paidBy,
            'totalAmount': totalAmount,
            'title': title,
            'participants': participants,
            'date': date != null
                ? Timestamp.fromDate(date)
                : FieldValue.serverTimestamp(),
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // ============ QUERY SINGLE EXPENSE ============

  /// Lấy chi tiết chi phí
  Future<Map<String, dynamic>?> getExpense(String expenseId) async {
    try {
      final doc = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('expenses')
          .doc(expenseId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      return {'id': doc.id, ...data};
    } catch (e) {
      return null;
    }
  }

  // ============ STATISTICS ============

  /// Tính tổng chi phí của user (người trả)
  Future<double> getTotalPaidByUser(String userId) async {
    try {
      final snap = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('expenses')
          .where('paidBy', isEqualTo: userId)
          .get();

      double total = 0;
      for (final doc in snap.docs) {
        final amount = doc.data()['totalAmount'];
        if (amount is num) {
          total += amount.toDouble();
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Lấy số lượng chi phí
  Future<int> getExpenseCount() async {
    try {
      final snap = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('expenses')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
