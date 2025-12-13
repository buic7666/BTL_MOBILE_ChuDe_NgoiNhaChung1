import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import 'add_expense_screen.dart';

class FinanceMainScreen extends StatefulWidget {
  const FinanceMainScreen({super.key});

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  int _selectedToggle = 0; // 0 = Ai nợ ai (default), 1 = Chi tiêu

  // temporary in-memory expenses while backend isn't wired
  final List<Map<String, dynamic>> _expenses = [
    {
      'title': 'Tiền điện chung',
      'subtitle': 'An đã trả - Chia đều',
      'date': null,
      'amount': 125000.0,
      'payer': 'An',
    },
  ];

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
      backgroundColor: AppColors.bgLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddExpenseScreen(),
          );

          if (!mounted) return;

          if (result != null) {
            final prevNet = _computeNetBalances();

            // ensure date
            result['date'] = result['date'] ?? DateTime.now();

            // build subtitle based on split mode
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

            // compute new net and produce notifications
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(messages.join('\n')),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
        backgroundColor: AppColors.accentPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBigBalanceCard(
                      'Số tiền bạn được trả ',
                      totalOweYou,
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigBalanceCard(
                      'Số tiền bạn đang nợ ',
                      totalYouOwe,
                      isPositive: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildToggleButtons(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: _selectedToggle == 0
                      ? _buildTransactionList()
                      : _buildExpensesList(formatter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final net = _computeNetBalances();

    // Split into owes-you (positive) and you-owe (negative)
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
        padding: EdgeInsets.only(top: 12),
        child: Center(child: Text('Không có khoản nợ')),
      );
    }

    Widget makeSection(String title, List<Map<String, dynamic>> list) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...list.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFB39DDB),
                      child: Text((_displayName((e['id'] as String))[0])),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nhấn để thanh toán',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format((e['amountValue'] as double)),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (e['isPositive'] as bool)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final combined = [...owesYou, ...youOwe];

    if (combined.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: Text('Không có khoản nợ')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: combined
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFB39DDB),
                      child: Text((_displayName((e['id'] as String))[0])),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nhấn để thanh toán',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format((e['amountValue'] as double)),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (e['isPositive'] as bool)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
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

      // default: equal split among all members
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
        for (final m in members)
          shares[m] = selected.contains(m) ? perShare : 0.0;
      } else {
        // equal
        final per = amount / members.length;
        for (final m in members) shares[m] = per;
      }

      // Update net balances relative to 'you'
      if (payer == 'you') {
        // you paid => others owe you their share
        for (final m in members) {
          if (m == 'you') continue;
          net[m] = (net[m] ?? 0.0) + (shares[m] ?? 0.0);
        }
      } else {
        // someone else paid => you may owe them your share
        final youShare = shares['you'] ?? 0.0;
        net[payer] =
            (net[payer] ?? 0.0) - youShare; // negative means you owe them
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

  Widget _buildExpensesList(NumberFormat formatter) {
    final expenses = _expenses;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Column(
      children: expenses
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (() {
                              final d = e['date'];
                              final dateStr = d is DateTime
                                  ? dateFormatter.format(d)
                                  : (d?.toString() ?? '');

                              final subtitle = e['subtitle'] as String?;
                              if (subtitle != null && subtitle.isNotEmpty) {
                                return '$subtitle · $dateStr';
                              }

                              // fallback: try to build subtitle from payer / splitMode
                              final payerRaw = (e['payer'] ?? '').toString();
                              String payerName;
                              final pr = payerRaw.toLowerCase();
                              if (pr == 'you' ||
                                  payerRaw == 'bạn' ||
                                  pr == 'ban')
                                payerName = 'Bạn';
                              else if (pr == 'an')
                                payerName = 'An';
                              else if (pr == 'binh' || pr == 'bình')
                                payerName = 'Bình';
                              else if (pr == 'chi')
                                payerName = 'Chi';
                              else if (payerRaw.isEmpty)
                                payerName = '';
                              else
                                payerName = payerRaw;

                              final splitRaw = (e['splitMode'] ?? '')
                                  .toString();
                              String splitDesc;
                              if (splitRaw.contains('percent'))
                                splitDesc = 'Phần trăm';
                              else if (splitRaw.contains('perPerson') ||
                                  splitRaw.contains('per_person'))
                                splitDesc = 'Theo người';
                              else
                                splitDesc = 'Chia đều';

                              if (payerName.isNotEmpty)
                                return '$payerName đã trả - $splitDesc · $dateStr';
                              return '$splitDesc · $dateStr';
                            })(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatter.format(e['amount'] as double),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E54E9), Color(0xFF5A31D8)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: const Center(
        child: Text(
          'Tài chính',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBigBalanceCard(
    String title,
    double amount, {
    required bool isPositive,
  }) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final bg = isPositive ? const Color(0xFFE8FFF3) : const Color(0xFFFFE8E8);
    final textColor = isPositive
        ? const Color(0xFF128C4A)
        : const Color(0xFFCF2E2E);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedToggle = 0),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedToggle == 0
                    ? const Color.fromARGB(255, 152, 25, 236)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  'Ai nợ ai',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _selectedToggle == 0
                        ? Colors.white
                        : AppColors.textPrimary,
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
              decoration: BoxDecoration(
                color: _selectedToggle == 1
                    ? const Color.fromARGB(255, 148, 33, 224)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  'Chi tiêu',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _selectedToggle == 1
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
