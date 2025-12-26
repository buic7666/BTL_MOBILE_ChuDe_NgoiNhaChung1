/// Model đại diện cho một khoản chi tiêu
class ExpenseModel {
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final String payer;
  final String? splitMode;
  final Map<String, dynamic>? splitDetails;
  final List<String>? selectedMembers;

  ExpenseModel({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.payer,
    this.splitMode,
    this.splitDetails,
    this.selectedMembers,
  });

  /// Tạo ExpenseModel từ Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      date: map['date'] as DateTime? ?? DateTime.now(),
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      payer: map['payer'] as String? ?? '',
      splitMode: map['splitMode'] as String?,
      splitDetails: map['splitDetails'] as Map<String, dynamic>?,
      selectedMembers: map['selectedMembers'] is List
          ? (map['selectedMembers'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  /// Chuyển ExpenseModel thành Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'date': date,
      'amount': amount,
      'payer': payer,
      'splitMode': splitMode,
      'splitDetails': splitDetails,
      'selectedMembers': selectedMembers,
    };
  }
}
