/// Model đại diện cho một khoản nợ giữa 2 người
class BalanceModel {
  final String id;
  final String fromUserId; // người nợ
  final String toUserId; // người được nợ
  final double amount; // số tiền nợ
  final String status; // unpaid | paying | paid
  final DateTime? paidAt; // thời gian người nợ bấm thanh toán
  final DateTime? confirmedAt; // thời gian người được nợ xác nhận nhận tiền
  final DateTime updatedAt;

  BalanceModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.status,
    this.paidAt,
    this.confirmedAt,
    required this.updatedAt,
  });

  /// Tạo BalanceModel từ Map
  factory BalanceModel.fromMap(String id, Map<String, dynamic> map) {
    return BalanceModel(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      status: map['status'] as String? ?? 'unpaid',
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as dynamic).toDate()
          : null,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as dynamic).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  /// Chuyển BalanceModel thành Map
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'status': status,
      'paidAt': paidAt,
      'confirmedAt': confirmedAt,
      'updatedAt': updatedAt,
    };
  }

  /// Tạo bản sao với các trường được cập nhật
  BalanceModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    double? amount,
    String? status,
    DateTime? paidAt,
    DateTime? confirmedAt,
    DateTime? updatedAt,
  }) {
    return BalanceModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'BalanceModel('
      'id: $id, '
      'fromUserId: $fromUserId, '
      'toUserId: $toUserId, '
      'amount: $amount, '
      'status: $status, '
      'paidAt: $paidAt, '
      'confirmedAt: $confirmedAt, '
      'updatedAt: $updatedAt)';
}
