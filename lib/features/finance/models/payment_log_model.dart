/// Model đại diện cho một khoản thanh toán (lịch sử chốt sổ)
class PaymentLogModel {
  final String id;
  final String fromUserId; // người đã trả
  final String toUserId; // người đã nhận
  final double amount; // số tiền đã thanh toán
  final DateTime paidAt; // thời gian người nợ bấm thanh toán
  final DateTime confirmedAt; // thời gian người được nợ xác nhận

  PaymentLogModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.paidAt,
    required this.confirmedAt,
  });

  /// Tạo PaymentLogModel từ Map
  factory PaymentLogModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentLogModel(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as dynamic).toDate()
          : DateTime.now(),
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  /// Chuyển PaymentLogModel thành Map
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'paidAt': paidAt,
      'confirmedAt': confirmedAt,
    };
  }

  @override
  String toString() =>
      'PaymentLogModel('
      'id: $id, '
      'fromUserId: $fromUserId, '
      'toUserId: $toUserId, '
      'amount: $amount, '
      'paidAt: $paidAt, '
      'confirmedAt: $confirmedAt)';
}
