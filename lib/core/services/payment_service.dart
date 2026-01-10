import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _houseId;

  PaymentService({required String houseId}) : _houseId = houseId;

  // ============ STREAM BALANCES (AI NỢ AI) ============

  /// Stream all debts của user (những khoản user nợ người khác)
  Stream<List<Map<String, dynamic>>> myDebtsStream(String userId) {
    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('balances')
        .doc(userId)
        .collection('debts')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {
              'toUserId': doc.id, // người được nợ
              'amount': data['amount'] ?? 0.0,
              'updatedAt': data['updatedAt'],
            };
          }).toList(),
        );
  }

  /// Stream all credits của user (những khoản người khác nợ user)
  Stream<List<Map<String, dynamic>>> myCreditsStream(String userId) {
    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('balances')
        .snapshots()
        .map((snap) {
          final List<Map<String, dynamic>> result = [];
          for (final doc in snap.docs) {
            final fromUserId = doc.id;
            final debts = doc.data()['debts'] as Map<String, dynamic>? ?? {};

            // Tìm debt nếu user là người được nợ
            if (debts.containsKey(userId)) {
              final debtData = debts[userId];
              result.add({
                'fromUserId': fromUserId,
                'amount': debtData['amount'] ?? 0.0,
                'updatedAt': debtData['updatedAt'],
              });
            }
          }
          return result;
        });
  }

  /// Get tổng tiền nợ của user
  Future<double> getTotalDebt(String userId) async {
    try {
      final snap = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('balances')
          .doc(userId)
          .collection('debts')
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

  /// Get tổng tiền người khác nợ user
  Future<double> getTotalCredit(String userId) async {
    try {
      final snap = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('balances')
          .get();

      double total = 0;
      for (final doc in snap.docs) {
        final debts = doc.data()['debts'] as Map<String, dynamic>? ?? {};
        if (debts.containsKey(userId)) {
          final amount = debts[userId]['amount'];
          if (amount is num) {
            total += amount.toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // ============ PAYMENT ACTIONS ============

  /// A trả B (1 bước – không cần confirm)
  /// Cloud Function sẽ:
  /// 1. Lấy balance hiện tại
  /// 2. Ghi payment_logs (status: confirmed)
  /// 3. XÓA balance
  Future<void> processPayment({
    required String from, // người nợ
    required String to, // người được nợ
  }) async {
    try {
      // Ghi payment request vào Firestore
      // Cloud Function listener sẽ xử lý tự động
      await _db
          .collection('houses')
          .doc(_houseId)
          .collection('payment_requests')
          .add({
            'from': from,
            'to': to,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // ============ STREAM PAYMENT LOGS (LỊCH SỬ) ============

  /// Stream lịch sử thanh toán
  Stream<List<Map<String, dynamic>>> paymentLogsStream() {
    return _db
        .collection('houses')
        .doc(_houseId)
        .collection('payment_logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'from': data['from'],
              'to': data['to'],
              'amount': data['amount'],
              'status': data['status'],
              'createdAt': data['createdAt'],
            };
          }).toList(),
        );
  }

  /// Get balance chi tiết (từ → tới)
  Future<double> getBalance(String fromUserId, String toUserId) async {
    try {
      final doc = await _db
          .collection('houses')
          .doc(_houseId)
          .collection('balances')
          .doc(fromUserId)
          .collection('debts')
          .doc(toUserId)
          .get();

      if (!doc.exists) return 0.0;
      final amount = doc.data()?['amount'];
      return amount is num ? amount.toDouble() : 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
