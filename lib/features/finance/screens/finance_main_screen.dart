import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/finance_logic.dart';
import '../widgets/balance_cards.dart';
import '../widgets/expense_item.dart';
import '../widgets/filter_toggle.dart';
import '../widgets/finance_header.dart';
import '../widgets/transaction_item.dart';
import 'add_expense_screen.dart';
import 'payment_screen.dart';
import '../../../core/services/finance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/house_service.dart';

class FinanceMainScreen extends StatefulWidget {
  const FinanceMainScreen({super.key});

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  int _selectedToggle = 0; // 0 = Ai nợ ai, 1 = Chi tiêu

  final List<Map<String, dynamic>> _expenses = [];

  // Track settlements per member (positive/negative deltas applied to net balances)
  final Map<String, double> _settlements = {};

  late final FinanceService _financeService;
  String? _houseId;
  Map<String, double>? _materializedNet;

  @override
  void initState() {
    super.initState();
    // Resolve current houseId for the authenticated user
    final auth = AuthService();
    final houseSvc = HouseService();
    final uid = auth.currentFirebaseUser?.uid;
    if (uid != null) {
      houseSvc.getHouseId(uid).then((hid) {
        if (!mounted) return;
        setState(() {
          _houseId = hid;
          _financeService = FinanceService(houseId: _houseId);
        });

        // Listen to expenses from Firestore (scoped by house)
        _financeService.expensesStream().listen((items) {
          if (!mounted) return;
          setState(() {
            _expenses
              ..clear()
              ..addAll(items);
          });
        });

        // Listen to settlements from Firestore (scoped by house)
        _financeService.settlementsStream().listen((m) {
          if (!mounted) return;
          setState(() {
            _settlements
              ..clear()
              ..addAll(m);
          });
        });

        // Listen to materialized balances from Cloud Functions
        _financeService.balancesStream().listen((net) {
          if (!mounted) return;
          setState(() {
            _materializedNet = net;
          });
        });
      });
    } else {
      // Fallback when no user: use unscoped service
      _financeService = FinanceService();
      _financeService.expensesStream().listen((items) {
        if (!mounted) return;
        setState(() {
          _expenses
            ..clear()
            ..addAll(items);
        });
      });
      _financeService.settlementsStream().listen((m) {
        if (!mounted) return;
        setState(() {
          _settlements
            ..clear()
            ..addAll(m);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Prefer materialized balances from Cloud Functions when available
    final net = _materializedNet ?? _computeNetBalances();
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

            // Persist to Firestore; UI will update via stream
            await _financeService.addExpense(result);

            // Compute message diff optimistically using current list + new result
            final newNet = computeNetBalances([
              ..._expenses,
              result,
            ], _settlements);
            final messages = <String>[];
            final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            for (final id in ['an', 'binh', 'chi']) {
              final prev = prevNet[id] ?? 0.0;
              final now = newNet[id] ?? 0.0;
              final diff = now - prev;

              if (prev > 0 && now > 0 && diff > 0.49) {
                messages.add(
                  '${_displayName(id)} nợ bạn thêm ${nf.format(diff / 2)}',
                );
              } else if (prev < 0 && now < 0 && diff < -0.49) {
                messages.add(
                  'Bạn nợ ${_displayName(id)} thêm ${nf.format(diff.abs() / 2)}',
                );
              } else if (prev <= 0 && now > 0) {
                messages.add(
                  '${_displayName(id)} giờ nợ bạn ${nf.format(now.abs() / 2)}',
                );
              } else if (prev >= 0 && now < 0) {
                messages.add(
                  'Bạn giờ nợ ${_displayName(id)} ${nf.format(now.abs() / 2)}',
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
                    const FinanceHeader(title: 'Tài chính'),

                    const SizedBox(height: 20),

                    // Balance Cards
                    BalanceCards(
                      totalOweYou: totalOweYou,
                      totalYouOwe: totalYouOwe,
                    ),

                    const SizedBox(height: 24),

                    // Filter Buttons
                    FilterToggle(
                      selectedToggle: _selectedToggle,
                      onToggleChanged: (value) {
                        setState(() => _selectedToggle = value);
                      },
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
          child: TransactionItem(
            initial: _displayName(e['id'] as String)[0],
            color: _getAvatarColor(e['id'] as String),
            title: e['name'] as String,
            subtitle: 'Nhấn để thanh toán',
            amount: formatter.format(e['amountValue'] as double),
            isPositive: e['isPositive'] as bool,
            onTap: () => _handleTransactionTap(e),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleTransactionTap(Map<String, dynamic> e) async {
    // Parse tên từ title
    String fromName = '';
    String toName = '';
    final title = e['name'] as String;
    if (title.contains('→')) {
      final parts = title.split('→');
      fromName = parts[0].trim();
      toName = parts.length > 1 ? parts[1].trim() : '';
    }

    final amountValue = e['amountValue'] as double;
    final isPositive = e['isPositive'] as bool;
    final memberId = e['id'] as String;

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
            result['action']?.toString() ?? (isPositive ? 'received' : 'paid');

        // If action == 'received' => member paid you (they owed you)
        // If action == 'paid' => you paid member (you owed them)
        final delta = action == 'received' ? -amountValue : amountValue;
        _settlements[memberId] = (_settlements[memberId] ?? 0.0) + delta;
      });

      // Persist settlement to Firestore
      try {
        await _financeService.addSettlement(
          memberId: memberId,
          delta:
              ((result['action']?.toString() ??
                      (isPositive ? 'received' : 'paid')) ==
                  'received'
              ? -amountValue
              : amountValue),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi ghi nhận thanh toán: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }

      final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
      final verb =
          (result['action'] ?? (isPositive ? 'received' : 'paid')) == 'received'
          ? 'nhận'
          : 'đã thanh toán';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã $verb ${nf.format(amountValue)} từ $fromName'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
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
          child: ExpenseItem(
            title: e['title'] as String,
            subtitle: _buildExpenseSubtitle(e, dateFormatter),
            amount: formatter.format(e['amount'] as double),
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
    return computeNetBalances(_expenses, _settlements);
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
