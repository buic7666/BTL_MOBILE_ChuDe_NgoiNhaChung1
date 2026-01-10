import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget hiển thị hai card số dư (được trả và đang nợ)
class BalanceCards extends StatelessWidget {
  final double totalOweYou;
  final double totalYouOwe;

  const BalanceCards({
    Key? key,
    required this.totalOweYou,
    required this.totalYouOwe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Green Card - Số tiền được trả
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFB8F4D4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số tiền bạn được trả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatter.format(totalOweYou),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5CFF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pink Card - Số tiền đang nợ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB8B8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số tiền bạn đang nợ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatter.format(totalYouOwe),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5CFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
