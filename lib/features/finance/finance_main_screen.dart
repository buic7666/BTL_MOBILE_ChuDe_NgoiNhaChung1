import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_expense_screen.dart';
import 'payment_screen.dart';

class FinanceMainScreen extends StatefulWidget {
  const FinanceMainScreen({super.key});

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  int _selectedToggle = 0; // 0 = Ai nợ ai, 1 = Chi tiêu

  final List<Map<String, dynamic>> _expenses = [
    {
      'title': 'Tiền điện chung',
      'subtitle': 'An đã trả - Chia đều',
      'date': DateTime.now(),
      'amount': 125000.0,
      'payer': 'An',
    },
  ];

  // Track settlements per member (positive/negative deltas applied to net balances)
  final Map<String, double> _settlements = {};

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final net = _computeNetBalances();
    final totalOweYou = net.entries
        .where((e) => e.key != 'you' && e.value > 0.5)
        .fold(0.0, (p, e) => p + e.value);
    final totalYouOwe = net.entries
        .where((e) => e.key != 'you' && e.value < -0.5)
        .fold(0.0, (p, e) => p + e.value.abs());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddExpenseScreen(),
          );

          if (!mounted) return;

          if (result != null) {
            final prevNet = _computeNetBalances();

            result['date'] = result['date'] ?? DateTime.now();

            final payerRaw = (result['payer'] ?? '').toString();
            String payerName = _displayName(_normalizeId(payerRaw));
            final splitRaw = (result['splitMode'] ?? '').toString();
            String splitDesc;
            if (splitRaw.contains('percent')) {
              splitDesc = 'Phần trăm';
            } else if (splitRaw.contains('perPerson') ||
                splitRaw.contains('per_person')) {
              splitDesc = 'Theo người';
            } else {
              splitDesc = 'Chia đều';
            }

            result['subtitle'] = '$payerName đã trả - $splitDesc';

            setState(() {
              _expenses.insert(0, result);
            });

            final newNet = _computeNetBalances();
            final messages = <String>[];
            final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            for (final id in ['an', 'binh', 'chi']) {
              final prev = prevNet[id] ?? 0.0;
              final now = newNet[id] ?? 0.0;
              final diff = now - prev;

              if (prev > 0 && now > 0 && diff > 0.49) {
                messages.add(
                  '${_displayName(id)} nợ bạn thêm ${nf.format(diff)}',
                );
              } else if (prev < 0 && now < 0 && diff < -0.49) {
                messages.add(
                  'Bạn nợ ${_displayName(id)} thêm ${nf.format(diff.abs())}',
                );
              } else if (prev <= 0 && now > 0) {
                messages.add(
                  '${_displayName(id)} giờ nợ bạn ${nf.format(now.abs())}',
                );
              } else if (prev >= 0 && now < 0) {
                messages.add(
                  'Bạn giờ nợ ${_displayName(id)} ${nf.format(now.abs())}',
                );
              }
            }

            if (messages.isNotEmpty) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(messages.join('\n')),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
        backgroundColor: const Color(0xFF6B5CFF),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C5CFF), Color(0xFF6B4FE8)],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tài chính',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Text(
                          //   'Ví: ${formatter.format(_walletBalance)}',
                          //   style: const TextStyle(
                          //     fontSize: 13,
                          //     fontWeight: FontWeight.w500,
                          //     color: Colors.white70,
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Balance Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Green Card
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

                          // Pink Card
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
                    ),

                    const SizedBox(height: 24),

                    // Filter Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swap_vert,
                            size: 20,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedToggle = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedToggle == 0
                                      ? const Color(0xFF7C5CFF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedToggle == 0
                                        ? const Color(0xFF7C5CFF)
                                        : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Ai nợ ai',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedToggle == 0
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedToggle = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedToggle == 1
                                      ? const Color(0xFF7C5CFF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedToggle == 1
                                        ? const Color(0xFF7C5CFF)
                                        : const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Chi tiêu',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedToggle == 1
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _selectedToggle == 0
                          ? _buildTransactionList()
                          : _buildExpensesList(formatter),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final net = _computeNetBalances();

    final owesYou = net.entries
        .where((e) => e.key != 'you' && e.value > 0.5)
        .map(
          (e) => {
            'id': e.key,
            'name': '${_displayName(e.key)} → Bạn',
            'amountValue': e.value,
            'isPositive': true,
          },
        )
        .toList();

    final youOwe = net.entries
        .where((e) => e.key != 'you' && e.value < -0.5)
        .map(
          (e) => {
            'id': e.key,
            'name': 'Bạn → ${_displayName(e.key)}',
            'amountValue': e.value.abs(),
            'isPositive': false,
          },
        )
        .toList();

    if (owesYou.isEmpty && youOwe.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            'Không có khoản nợ',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    final combined = [...owesYou, ...youOwe];

    return Column(
      children: combined.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTransactionItem(
            initial: _displayName(e['id'] as String)[0],
            color: _getAvatarColor(e['id'] as String),
            title: e['name'] as String,
            subtitle: 'Nhấn để thanh toán',
            amount: formatter.format(e['amountValue'] as double),
            amountValue: e['amountValue'] as double,
            isPositive: e['isPositive'] as bool,
            memberId: e['id'] as String,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem({
    required String initial,
    required Color color,
    required String title,
    required String subtitle,
    required String amount,
    required double amountValue,
    required bool isPositive,
    required String memberId,
  }) {
    return GestureDetector(
      onTap: () async {
        // Parse tên từ title
        String fromName = '';
        String toName = '';
        if (title.contains('→')) {
          final parts = title.split('→');
          fromName = parts[0].trim();
          toName = parts.length > 1 ? parts[1].trim() : '';
        }

        // Mở màn hình thanh toán
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              fromName: fromName,
              toName: toName,
              amount: amountValue,
              date: DateTime.now(),
              description: 'Chi phí chung',
              isReceive: isPositive,
            ),
          ),
        );

        // Xử lý khi confirm - GHI NHẬN THANH TOÁN (settlement)
        if (result != null && result['confirmed'] == true && mounted) {
          setState(() {
            final action =
                result['action']?.toString() ??
                (isPositive ? 'received' : 'paid');

            // If action == 'received' => member paid you (they owed you)
            // If action == 'paid' => you paid member (you owed them)
            final delta = action == 'received' ? -amountValue : amountValue;
            _settlements[memberId] = (_settlements[memberId] ?? 0.0) + delta;
          });

          final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
          final verb =
              (result['action'] ?? (isPositive ? 'received' : 'paid')) ==
                  'received'
              ? 'nhận'
              : 'đã thanh toán';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã $verb ${nf.format(amountValue)} từ $fromName',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String id) {
    switch (id) {
      case 'an':
        return const Color(0xFFD946EF);
      case 'binh':
        return const Color(0xFFD946EF);
      case 'chi':
        return const Color(0xFFC084FC);
      default:
        return const Color(0xFFB39DDB);
    }
  }

  Widget _buildExpensesList(NumberFormat formatter) {
    final dateFormatter = DateFormat('dd/MM/yyyy');

    if (_expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            'Chưa có chi tiêu nào',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: _expenses.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildExpenseSubtitle(e, dateFormatter),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatter.format(e['amount'] as double),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _buildExpenseSubtitle(
    Map<String, dynamic> e,
    DateFormat dateFormatter,
  ) {
    final d = e['date'];
    final dateStr = d is DateTime ? dateFormatter.format(d) : '';

    final subtitle = e['subtitle'] as String?;
    if (subtitle != null && subtitle.isNotEmpty) {
      return dateStr.isNotEmpty ? '$subtitle · $dateStr' : subtitle;
    }

    final payerRaw = (e['payer'] ?? '').toString();
    final payerName = _displayName(_normalizeId(payerRaw));
    final splitRaw = (e['splitMode'] ?? '').toString();

    String splitDesc;
    if (splitRaw.contains('percent')) {
      splitDesc = 'Phần trăm';
    } else if (splitRaw.contains('perPerson') ||
        splitRaw.contains('per_person')) {
      splitDesc = 'Theo người';
    } else {
      splitDesc = 'Chia đều';
    }

    final base = payerName.isNotEmpty
        ? '$payerName đã trả - $splitDesc'
        : splitDesc;
    return dateStr.isNotEmpty ? '$base · $dateStr' : base;
  }

  Map<String, double> _computeNetBalances() {
    final members = ['you', 'an', 'binh', 'chi'];
    final Map<String, double> net = {for (var m in members) m: 0.0};

    for (final e in _expenses) {
      final amount = (e['amount'] is num)
          ? (e['amount'] as num).toDouble()
          : 0.0;
      final payerRaw = (e['payer'] ?? '').toString();
      final payer = _normalizeId(payerRaw);
      final splitRaw = (e['splitMode'] ?? '').toString();

      Map<String, double> shares = {for (var m in members) m: 0.0};

      if (splitRaw.contains('percent')) {
        final sd = e['splitDetails'];
        final pct = sd is Map
            ? (sd['percent'] is num
                  ? (sd['percent'] as num).toDouble()
                  : double.tryParse(sd['percent'].toString()) ?? 0.0)
            : 0.0;
        final pctMember = sd is Map
            ? _normalizeId(sd['memberId']?.toString() ?? '')
            : '';
        final percentAmount = amount * (pct / 100.0);
        final others = members.where((m) => m != pctMember).toList();
        final perOther = others.isNotEmpty
            ? ((amount - percentAmount) / others.length)
            : 0.0;
        for (final m in members) {
          shares[m] = (m == pctMember) ? percentAmount : perOther;
        }
      } else if (splitRaw.contains('perPerson') ||
          e['selectedMembers'] != null) {
        final selected = e['selectedMembers'] is List
            ? (e['selectedMembers'] as List)
                  .map((x) => _normalizeId(x.toString()))
                  .where((x) => members.contains(x))
                  .toList()
            : members;
        final sc = selected.isNotEmpty ? selected.length : 1;
        final perShare = amount / sc;
        for (final m in members) {
          shares[m] = selected.contains(m) ? perShare : 0.0;
        }
      } else {
        final per = amount / members.length;
        for (final m in members) {
          shares[m] = per;
        }
      }

      if (payer == 'you') {
        for (final m in members) {
          if (m == 'you') continue;
          net[m] = (net[m] ?? 0.0) + (shares[m] ?? 0.0);
        }
      } else {
        final youShare = shares['you'] ?? 0.0;
        net[payer] = (net[payer] ?? 0.0) - youShare;
      }
    }

    // Apply recorded settlements (deltas) so confirmed payments remove/reduce debts
    for (final m in members) {
      if (_settlements.containsKey(m)) {
        net[m] = (net[m] ?? 0.0) + (_settlements[m] ?? 0.0);
      }
    }

    return net;
  }

  String _normalizeId(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('ban') || s.contains('bạn')) return 'you';
    if (s.contains('an')) return 'an';
    if (s.contains('binh') || s.contains('bình')) return 'binh';
    if (s.contains('chi')) return 'chi';
    return s;
  }

  String _displayName(String id) {
    switch (id) {
      case 'you':
        return 'Bạn';
      case 'an':
        return 'An';
      case 'binh':
        return 'Bình';
      case 'chi':
        return 'Chi';
      default:
        return id;
    }
  }
}
