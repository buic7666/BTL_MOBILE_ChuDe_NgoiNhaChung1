import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final String houseId;
  final String expenseId;
  final Map<String, dynamic>? initialExpense;

  const ExpenseDetailScreen({
    super.key,
    required this.houseId,
    required this.expenseId,
    this.initialExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        backgroundColor: const Color(0xFF6B5CFF),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadExpense(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy hóa đơn'));
          }
          final expense = snapshot.data!;
          final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
          final title = (expense['title'] as String?)?.trim().isNotEmpty == true
              ? (expense['title'] as String)
              : 'Chi phí chung';
          final payerId = (expense['payer'] ?? expense['paidBy'] ?? '')
              .toString();
          final payerName = expense['payerName'] as String? ?? payerId;
          final date = _asDate(expense['date']);
          final total =
              ((expense['totalAmount'] ?? expense['amount']) as num?)
                  ?.toDouble() ??
              0.0;
          final splits = (expense['splits'] as Map<String, dynamic>?) ?? {};
          final splitMode = expense['splitMode']?.toString() ?? '';
          final percentMemberId = expense['percentMemberId']?.toString();
          final percentValue = (expense['percentValue'] as num?)?.toDouble();
          final sumSplits = splits.values
              .map((v) => (v as num?)?.toDouble() ?? 0.0)
              .fold<double>(0.0, (a, b) => a + b);
          final payerShare = (total - sumSplits) < 0
              ? 0.0
              : (total - sumSplits);
          final participantCount =
              splits.length; // chỉ tính người cùng chia (trừ người trả)
          final avgPerPerson = splits.isNotEmpty
              ? sumSplits / splits.length
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  children: [
                    _titleRow(title),
                    const SizedBox(height: 12),
                    _infoRow('Người trả', payerName),
                    if (date != null) ...[
                      const SizedBox(height: 8),
                      _infoRow('Ngày', DateFormat('dd/MM/yyyy').format(date)),
                    ],
                    const SizedBox(height: 8),
                    _infoRow('Tổng cộng', nf.format(total), boldValue: true),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  children: [
                    const Text(
                      'Cách chia',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Hình thức', _splitModeLabel(splitMode)),
                    _infoRow('Số người chia', '$participantCount'),
                    if (sumSplits > 0)
                      _infoRow(
                        'Tổng phần chia (mọi người nợ bạn)',
                        nf.format(sumSplits),
                      ),
                    if (payerShare > 0)
                      _infoRow('Phần của người trả', nf.format(payerShare)),
                    if (avgPerPerson > 0)
                      _infoRow('Trung bình mỗi người', nf.format(avgPerPerson)),
                    if (splitMode.contains('percent') &&
                        percentMemberId != null)
                      _infoRow(
                        'Phần trăm riêng',
                        percentValue != null
                            ? '${percentValue.toStringAsFixed(0)}% cho ${_displayName(expense, percentMemberId)}'
                            : _displayName(expense, percentMemberId),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCard(
                  children: [
                    const Text(
                      'Chi tiết chia',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (payerShare > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              payerName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              nf.format(payerShare),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...splits.entries.map((entry) {
                      final uid = entry.key.toString();
                      final name = _displayName(expense, uid);
                      final value = (entry.value as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              nf.format(value),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadExpense() async {
    if (initialExpense != null) {
      final copy = Map<String, dynamic>.from(initialExpense!);
      final ts = copy['date'];
      if (ts is Timestamp) copy['date'] = ts.toDate();
      return copy;
    }

    final snap = await FirebaseFirestore.instance
        .collection('houses')
        .doc(houseId)
        .collection('expenses')
        .doc(expenseId)
        .get();

    if (!snap.exists) {
      throw Exception('Expense not found');
    }

    final data = {...snap.data() as Map<String, dynamic>, 'id': expenseId};
    final ts = data['date'];
    if (ts is Timestamp) data['date'] = ts.toDate();
    return data;
  }

  DateTime? _asDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  String _splitModeLabel(String mode) {
    if (mode.contains('percent')) return 'Chia phần trăm';
    if (mode.contains('perPerson')) return 'Chia theo người chọn';
    return 'Chia đều';
  }

  String _displayName(Map<String, dynamic> expense, String uid) {
    final map = expense['participantNames'] as Map<String, dynamic>?;
    if (map != null && map[uid] is String && (map[uid] as String).isNotEmpty) {
      return map[uid] as String;
    }
    if (expense['payer']?.toString() == uid &&
        expense['payerName'] is String &&
        (expense['payerName'] as String).isNotEmpty) {
      return expense['payerName'] as String;
    }
    return uid;
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool boldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: boldValue ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _titleRow(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
