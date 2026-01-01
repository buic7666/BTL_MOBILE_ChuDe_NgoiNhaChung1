import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/finance_logic.dart';
import '../widgets/balance_cards.dart';
import '../widgets/expense_item.dart';
import '../widgets/filter_toggle.dart';
import '../widgets/finance_header.dart';
import '../widgets/transaction_item.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'payment_screen.dart';
import '../../../core/services/finance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/house_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/expense_service.dart';
import '../../../models/user_profile.dart';

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
  late final ExpenseService _expenseService;
  final UserService _userService = UserService();
  final HouseService _houseService = HouseService();

  String? _houseId;
  String? _currentUserId;
  List<String> _memberIds = [];
  Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final auth = AuthService();
    final uid = auth.currentFirebaseUser?.uid;

    if (uid == null) return;

    _currentUserId = uid;

    // Lấy houseId
    final hid = await _houseService.getHouseId(uid);
    if (!mounted || hid == null) return;

    setState(() {
      _houseId = hid;
      _financeService = FinanceService(houseId: _houseId);
      _expenseService = ExpenseService(houseId: hid);
    });

    // Load members
    _houseService.houseMembersStream(hid).listen((memberIds) async {
      if (!mounted) return;

      setState(() {
        _memberIds = memberIds;
      });

      // Load user profiles cho tất cả members
      final profiles = await _userService.getUserProfiles(memberIds);
      if (!mounted) return;

      setState(() {
        _userProfiles = profiles;
      });
    });

    // Listen to expenses
    _financeService.expensesStream().listen((items) {
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(items);
      });
    });

    // Listen to settlements (legacy)
    _financeService.settlementsStream().listen((m) {
      if (!mounted) return;
      setState(() {
        _settlements
          ..clear()
          ..addAll(m);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Dùng _computeNetBalances() từ expenses + settlements
    // Tính một lần và truyền xuống để tránh lệch dữ liệu giữa thẻ tổng và danh sách
    final net = _computeNetBalances();
    final totalOweYou = net.entries
        .where((e) => e.key != _currentUserId && e.value > 0.5)
        .fold(0.0, (p, e) => p + e.value);
    final totalYouOwe = net.entries
        .where((e) => e.key != _currentUserId && e.value < -0.5)
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
            builder: (_) => AddExpenseScreen(
              currentUserId: _currentUserId,
              memberIds: _memberIds,
              userProfiles: _userProfiles,
            ),
          );

          if (!mounted) return;

          if (result != null && _houseId != null) {
            // Lấy thông tin người trả
            final payerIdRaw = result['payer'] as String?;
            if (payerIdRaw == null || payerIdRaw.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không xác định được người trả'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final payerId = payerIdRaw;

            print(
              '💰 AddExpense result: payer=$payerId, currentUser=$_currentUserId',
            );

            final totalAmount = (result['amount'] as num?)?.toDouble() ?? 0.0;
            final title = result['title'] as String? ?? 'Chi phí chung';
            final date = result['date'] as DateTime? ?? DateTime.now();
            final splitMode =
                result['splitMode'] as String? ?? 'SplitMode.equal';
            final splitDetails =
                result['splitDetails'] as Map<String, dynamic>?;
            final selectedMembers =
                (result['selectedMembers'] as List?)?.cast<String>() ?? [];

            // Participants: ưu tiên danh sách đã chọn, luôn bao gồm payer
            final participants = <String, bool>{};
            final participantIds =
                splitMode.contains('perPerson') && selectedMembers.isNotEmpty
                ? selectedMembers
                : _memberIds;
            for (final memberId in participantIds) {
              participants[memberId] = true;
            }
            participants[payerId] = true;

            try {
              print('🔥 BẮT ĐẦU GHI DỮ LIỆU');
              // 1️⃣ Xác định danh sách participants và tính toán split
              Map<String, double> splitAmounts =
                  {}; // { memberId: amount người đó phải trả }
              print('SplitMode USED: $splitMode');

              splitAmounts = _calculateSplitAmounts(
                splitMode: splitMode,
                splitDetails: splitDetails,
                payerId: payerId,
                totalAmount: totalAmount,
                selectedMembers: selectedMembers,
              );

              print('✅ Split amounts: $splitAmounts');

              // 2️⃣ Tạo expense
              final expenseRef = FirebaseFirestore.instance
                  .collection('houses')
                  .doc(_houseId)
                  .collection('expenses')
                  .doc();

              print('✅ Đang ghi expense...');
              await expenseRef.set({
                'createdBy': _currentUserId ?? 'unknown',
                'paidBy': payerId,
                'totalAmount': totalAmount,
                'title': title,
                'participants': participants,
                'splitMode': splitMode,
                'splitDetails': splitDetails ?? {},
                'selectedMembers': selectedMembers,
                'splits': splitAmounts,
                'date': Timestamp.fromDate(date),
                'createdAt': FieldValue.serverTimestamp(),
              });
              print('✅ Đã ghi expense: ${expenseRef.id}');

              // 3️⃣ Update balances (TẠO 2 CHIỀU NỢ) - theo splitAmounts
              for (final entry in splitAmounts.entries) {
                final memberId = entry.key;
                final amount = entry.value;

                if (amount <= 0.01) continue; // Bỏ qua nếu < 0.01

                print(
                  '💰 Đang update balance: $memberId nợ $payerId ($amount)',
                );

                // CHIỀU 1: memberId nợ payerId (view của người nợ)
                final debtRef1 = FirebaseFirestore.instance
                    .collection('houses')
                    .doc(_houseId)
                    .collection('balances')
                    .doc(memberId)
                    .collection('debts')
                    .doc(payerId);

                final balanceSnap1 = await debtRef1.get();
                double newAmount = amount;

                if (balanceSnap1.exists) {
                  final current = balanceSnap1.data();
                  newAmount =
                      ((current?['amount'] ?? 0) as num).toDouble() + amount;
                  print('   Cộng dồn chiều 1: $newAmount');
                } else {
                  print('   Tạo mới chiều 1: $newAmount');
                }

                await debtRef1.set({
                  'fromUserId': memberId,
                  'toUserId': payerId,
                  'amount': newAmount,
                  'status': 'unpaid',
                  'paidBy': false,
                  'confirmedBy': false,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                print('✅ Đã update balance chiều 1: $memberId → $payerId');

                // CHIỀU 2: payerId có được trả bởi memberId (view của người cho vay)
                final debtRef2 = FirebaseFirestore.instance
                    .collection('houses')
                    .doc(_houseId)
                    .collection('balances')
                    .doc(payerId)
                    .collection('debts')
                    .doc(memberId);

                final balanceSnap2 = await debtRef2.get();
                double newAmount2 = amount;

                if (balanceSnap2.exists) {
                  final current = balanceSnap2.data();
                  newAmount2 =
                      ((current?['amount'] ?? 0) as num).toDouble() + amount;
                } else {
                  print('   Tạo mới chiều 2: $newAmount2');
                }

                await debtRef2.set({
                  'fromUserId': payerId,
                  'toUserId': memberId,
                  'amount': newAmount2,
                  'status': 'unpaid',
                  'paidBy': false,
                  'confirmedBy': false,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                print('✅ Đã update balance chiều 2: $payerId → $memberId');
              }

              print('🎉 HOÀN THÀNH GHI DỮ LIỆU');

              // Đã ghi expense đúng với splits, không cần ghi lại
            } catch (e, stackTrace) {
              print('❌ LỖI: $e');
              print('Stack: $stackTrace');
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Lỗi thêm chi phí: $e'),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
              return;
            }

            // Hiển thị thông báo thành công
            final payerName = _getUserDisplayName(payerId);
            final numParticipants = participants.values
                .where((v) => v == true)
                .length;
            final splitAmount = totalAmount / numParticipants;
            final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Chi phí ${nf.format(totalAmount)} đã được thêm\n'
                  '💰 $payerName đã trả toàn bộ\n'
                  '👥 Chia cho $numParticipants người (${nf.format(splitAmount)}/người)',
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: const Color(0xFF10B981),
              ),
            );

            // Force rebuild UI ngay để cập nhật số tiền
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) setState(() {});
              });
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
                          ? _buildTransactionList(net)
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

  Widget _buildTransactionList(Map<String, double> net) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final owesYou = net.entries
        .where((e) => e.key != _currentUserId && e.value > 0.5)
        .map(
          (e) => {
            'id': e.key,
            'name': '${_getUserDisplayName(e.key)} nợ bạn',
            'amountValue': e.value,
            'isPositive': true,
          },
        )
        .toList();

    final youOwe = net.entries
        .where((e) => e.key != _currentUserId && e.value < -0.5)
        .map(
          (e) => {
            'id': e.key,
            'name': 'Bạn nợ ${_getUserDisplayName(e.key)}',
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

    final List<Map<String, dynamic>> combined = [...owesYou, ...youOwe];

    return Column(
      children: combined.map((e) {
        final userId = e['id'] as String;
        final isPositive = e['isPositive'] as bool;
        final subtitle = isPositive
            ? '${_getUserDisplayName(userId)} cần trả bạn'
            : 'Bạn cần trả ${_getUserDisplayName(userId)}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionItem(
            initial: _getUserInitial(userId),
            color: _getAvatarColor(userId),
            title: e['name'] as String,
            subtitle: subtitle,
            amount: formatter.format(e['amountValue'] as double),
            isPositive: isPositive,
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

    // Xác định fromUserId và toUserId
    final fromUserId = isPositive ? memberId : _currentUserId;
    final toUserId = isPositive ? _currentUserId : memberId;

    if (fromUserId == null || toUserId == null || _houseId == null) return;

    // Lấy tiêu đề hóa đơn gần nhất cho cặp này (để hiển thị rõ ràng)
    final expenseTitle = _findLatestExpenseTitle(
      payerId: fromUserId ?? '',
      debtorId: toUserId ?? '',
    );

    // Mở màn hình thanh toán
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          fromName: _getUserDisplayName(fromUserId ?? ''),
          toName: _getUserDisplayName(toUserId ?? ''),
          amount: amountValue,
          date: DateTime.now(),
          description: expenseTitle,
          isReceive: isPositive,
        ),
      ),
    );

    // Xử lý khi confirm - XÓA NỢ TRỰC TIẾP
    if (result != null && result['confirmed'] == true && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        // Xác định người nợ và người cho vay từ transaction
        // isPositive=true: memberId được trả (memberId là người nợ, current user là người cho vay)
        // isPositive=false: current user phải trả (current user là người nợ, memberId là người cho vay)
        final payerId = isPositive ? _currentUserId : memberId;
        final debtorId = isPositive ? memberId : _currentUserId;

        print('💳 PAYMENT DEBUG: isPositive=$isPositive, memberId=$memberId');
        print('💳 payerId=$payerId, debtorId=$debtorId');
        print('💳 currentUser=$_currentUserId');

        // Debt chính (chiều người nợ giữ)
        final debtRef = FirebaseFirestore.instance
            .collection('houses')
            .doc(_houseId)
            .collection('balances')
            .doc(debtorId)
            .collection('debts')
            .doc(payerId);

        // Debt đối xứng (để phía người cho vay cũng thấy)
        final mirrorDebtRef = FirebaseFirestore.instance
            .collection('houses')
            .doc(_houseId)
            .collection('balances')
            .doc(payerId)
            .collection('debts')
            .doc(debtorId);

        print('💳 Looking for: balances/$debtorId/debts/$payerId');

        // Kiểm tra/tạo debt doc để theo dõi trạng thái xác nhận
        final debtSnap = await debtRef.get();
        Map<String, dynamic> debtData = {};

        if (debtSnap.exists) {
          debtData = debtSnap.data() as Map<String, dynamic>;
        } else {
          print('⚠️ Debt không tồn tại, tạo mới để theo dõi xác nhận');
          debtData = {
            'paidBy': false,
            'confirmedBy': false,
            'settlementDone': false,
            'createdAt': FieldValue.serverTimestamp(),
          };
        }

        // Cập nhật flag xác nhận tương ứng
        // paidBy: người cho vay (payerId) xác nhận đã trả
        // confirmedBy: người nợ (debtorId) xác nhận đã nhận
        final userId = _currentUserId;
        if (userId == payerId) {
          debtData['paidBy'] = true;
          debtData['paidAt'] = FieldValue.serverTimestamp();
        } else if (userId == debtorId) {
          debtData['confirmedBy'] = true;
          debtData['confirmedAt'] = FieldValue.serverTimestamp();
        }

        // Áp dụng cho cả debt và mirrorDebt để hai phía thấy cùng trạng thái
        await Future.wait([
          debtRef.set(debtData, SetOptions(merge: true)),
          mirrorDebtRef.set(debtData, SetOptions(merge: true)),
        ]);
        print(
          '✅ Cập nhật cờ xác nhận: paidBy=${debtData['paidBy']}, confirmedBy=${debtData['confirmedBy']}',
        );

        // Kiểm tra trạng thái xác nhận
        final bothConfirmed =
            debtData['paidBy'] == true && debtData['confirmedBy'] == true;
        final settlementDone = debtData['settlementDone'] == true;

        print(
          '🔄 bothConfirmed=$bothConfirmed, settlementDone=$settlementDone',
        );

        // Helper: thực hiện trừ tiền + gạch settledPairs một lần (idempotent bằng settlementDone)
        Future<void> _settleOnce() async {
          print('💚 BẮT ĐẦU SETTLE (khi đã có 1 phía xác nhận)...');

          final expensesSnap = await FirebaseFirestore.instance
              .collection('houses')
              .doc(_houseId)
              .collection('expenses')
              .get();

          print('💚 Quét ${expensesSnap.docs.length} expenses...');

          int matchedCount = 0;
          double remainingToSettle = amountValue;

          for (final expenseDoc in expensesSnap.docs) {
            final expenseData = expenseDoc.data();
            final expensePayer = expenseData['paidBy'] as String?;
            final Map<String, dynamic> splits =
                (expenseData['splits'] as Map<String, dynamic>?) ?? {};

            print(
              '  - expense ${expenseDoc.id}: payer=$expensePayer, settled=${expenseData['settled']}',
            );
            print('    splits keys: ${splits.keys.toList()}');
            print('    debtorId=$debtorId, payerId=$payerId');

            // Tìm expense liên quan đến cặp payerId-debtorId (cả hai chiều)
            // Khi thanh toán net balance, cần gạch TẤT CẢ expense của cặp này
            double pairAmount = 0.0;
            if (expensePayer == payerId && splits.containsKey(debtorId)) {
              final debtorSplit = splits[debtorId];
              if (debtorSplit is num)
                pairAmount = (debtorSplit as num).toDouble();
            } else if (expensePayer == debtorId &&
                splits.containsKey(payerId)) {
              final payerSplit = splits[payerId];
              if (payerSplit is num)
                pairAmount = (payerSplit as num).toDouble();
            }

            if (pairAmount <= 0.0) continue;

            // Bỏ qua nếu expense đã mark settled cho cặp này
            final ids = [payerId, debtorId];
            ids.sort();
            final sortedPairKey = '${ids[0]}:${ids[1]}';
            final Map<String, dynamic> settledPairs =
                (expenseData['settledPairs'] as Map<String, dynamic>?) ?? {};
            if (settledPairs.containsKey(sortedPairKey)) continue;

            // Gạch TẤT CẢ expense của cặp này, bất kể amount
            // (vì net balance đã tính bù trừ, thanh toán net là thanh toán toàn bộ)
            print(
              '    🎯 MATCH! Gạch cặp $sortedPairKey trong expense ${expenseDoc.id} (split=$pairAmount)',
            );

            settledPairs[sortedPairKey] = {
              'settledAt': FieldValue.serverTimestamp(),
            };

            await expenseDoc.reference.update({'settledPairs': settledPairs});
            matchedCount++;
            remainingToSettle -= pairAmount;
            print('    ✔️ remaining còn lại: $remainingToSettle');

            // Tiếp tục gạch các expense khác của cặp này (không break sớm)
          }

          print(
            '💚 Đã đánh dấu settledPairs cho $matchedCount expense(s), còn lại chưa gạch: $remainingToSettle',
          );

          // Log payment để audit
          await FirebaseFirestore.instance
              .collection('houses')
              .doc(_houseId)
              .collection('payment_logs')
              .add({
                'fromUserId': fromUserId,
                'toUserId': toUserId,
                'amount': amountValue,
                'createdAt': FieldValue.serverTimestamp(),
              });

          // Chờ stream listener cập nhật từ expenses
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 200));
            setState(() {});
          }
        }

        // Chỉ settle khi cả hai đã bấm để đồng bộ hai phía
        if (bothConfirmed && !settlementDone) {
          await _settleOnce();
          await Future.wait([
            debtRef.set({'settlementDone': true}, SetOptions(merge: true)),
            mirrorDebtRef.set({
              'settlementDone': true,
            }, SetOptions(merge: true)),
          ]);
        }

        final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
        final memberName = _getUserDisplayName(memberId);

        String message;
        if (isPositive) {
          // Người khác đã trả nợ cho bạn
          message = bothConfirmed
              ? '✅ $memberName đã trả ${nf.format(amountValue)} cho bạn\n💚 Khoản nợ đã được thanh toán hoàn tất'
              : '✅ Bạn đã xác nhận nhận ${nf.format(amountValue)} từ $memberName\n⏳ Đang chờ $memberName xác nhận đã trả';
        } else {
          // Bạn đã trả nợ cho người khác
          message = bothConfirmed
              ? '✅ Bạn đã thanh toán ${nf.format(amountValue)} cho $memberName\n💙 Khoản nợ đã được giải quyết hoàn tất'
              : '✅ Bạn đã xác nhận trả ${nf.format(amountValue)} cho $memberName\n⏳ Đang chờ $memberName xác nhận đã nhận';
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý thanh toán: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Map<String, double> _calculateSplitAmounts({
    required String splitMode,
    Map<String, dynamic>? splitDetails,
    required String payerId,
    required double totalAmount,
    List<String>? selectedMembers,
  }) {
    final Map<String, double> splits = {};
    final members = _memberIds;

    if (splitMode.contains('percent')) {
      // CHIA %: một người chịu % riêng, phần còn lại chia đều cho những người khác (không gồm payer)
      final percent = (splitDetails?['percent'] ?? 0) as num;
      final percentMemberId = splitDetails?['memberId'] as String?;

      if (percentMemberId != null) {
        final pctAmount = totalAmount * percent / 100;
        final remainingAmount = totalAmount - pctAmount;

        // Danh sách còn lại để chia phần còn lại (không gồm payer và người % nếu họ là payer)
        final others = members
            .where((id) => id != payerId && id != percentMemberId)
            .toList();
        final perOther = others.isNotEmpty
            ? remainingAmount / others.length
            : 0.0;

        for (final memberId in members) {
          if (memberId == payerId) continue; // người trả không nợ chính mình

          if (memberId == percentMemberId && percentMemberId != payerId) {
            // Người được % (khác payer) chịu phần % riêng
            splits[memberId] = pctAmount;
          } else {
            // Các thành viên còn lại chịu phần chia đều của phần còn lại
            splits[memberId] = perOther;
          }
        }
      }
    } else if (splitMode.contains('perPerson')) {
      // CHIA THEO NGƯỜI: chỉ những người được chọn chia đều
      final selected = selectedMembers ?? [];
      if (selected.isEmpty) return splits;

      final per = totalAmount / selected.length;
      for (final memberId in selected) {
        if (memberId == payerId) continue; // người trả không nợ chính mình
        splits[memberId] = per;
      }
    } else {
      // CHIA ĐỀU: tất cả members chia đều (bao gồm cả payer)
      if (members.isEmpty) return splits;

      final per = totalAmount / members.length;
      for (final memberId in members) {
        if (memberId == payerId) continue; // người trả không nợ chính mình
        splits[memberId] = per;
      }
    }

    return splits;
  }

  Color _getAvatarColor(String id) {
    // Tạo màu từ hash của UID
    final hash = id.hashCode;
    final colors = [
      const Color(0xFFD946EF),
      const Color(0xFFC084FC),
      const Color(0xFFB39DDB),
      const Color(0xFF9333EA),
      const Color(0xFFA855F7),
      const Color(0xFF8B5CF6),
    ];
    return colors[hash.abs() % colors.length];
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
        // Dữ liệu từ Cloud Function có totalAmount, không có amount
        final amount = (e['totalAmount'] ?? e['amount']) as num?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ExpenseItem(
            title: e['title'] as String? ?? 'Chi phí chung',
            subtitle: _buildExpenseSubtitle(e, dateFormatter),
            amount: formatter.format((amount ?? 0).toDouble()),
            onTap: () => _openExpenseDetail(e),
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

    final payerId = (e['payer'] ?? e['paidBy'] ?? '').toString();
    final payerName = _getUserDisplayName(payerId);

    final splits = (e['splits'] as Map<String, dynamic>?) ?? {};
    final splitCount = splits.length;
    final sumSplits = splits.values
        .map((v) => (v as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a + b);

    final participantsData = e['participants'];
    final selectedMembers = (e['selectedMembers'] as List?)?.cast<String>();
    final splitMode = e['splitMode']?.toString() ?? '';

    int numParticipants = 0;
    if (splitCount > 0) {
      numParticipants = splitCount;
    } else if (selectedMembers != null && selectedMembers.isNotEmpty) {
      numParticipants = selectedMembers.length;
    } else if (participantsData is Map) {
      numParticipants = participantsData.values.where((v) => v == true).length;
    } else if (participantsData is List) {
      numParticipants = participantsData.length;
    }

    // Loại người trả khỏi số người chia nếu đang đếm tất cả participants (chỉ áp dụng khi chưa có splits cụ thể)
    if (splitCount == 0 && numParticipants > 0) {
      if (splitMode.contains('percent') || splitMode.contains('equal')) {
        numParticipants = ((numParticipants - 1).clamp(
          0,
          numParticipants,
        )).toInt();
      }
    }

    final totalAmount =
        ((e['totalAmount'] ?? e['amount']) as num?)?.toDouble() ?? 0.0;
    final nf = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    double perPerson;
    int displayCount;
    if (splitCount > 0) {
      perPerson = splitCount > 0 ? sumSplits / splitCount : 0.0;
      displayCount = splitCount;
    } else {
      perPerson = numParticipants > 0 ? totalAmount / numParticipants : 0.0;
      displayCount = numParticipants;
    }

    final splitDesc = displayCount > 0
        ? '💰 $payerName trả · 👥 Chia $displayCount người (${nf.format(perPerson)}/người)'
        : '💰 $payerName trả';

    return dateStr.isNotEmpty ? '$splitDesc · 📅 $dateStr' : splitDesc;
  }

  void _openExpenseDetail(Map<String, dynamic> e) {
    final expenseId = e['id'] as String?;
    if (_houseId == null || expenseId == null) return;

    final participantNames = <String, String>{};
    final splits = e['splits'] as Map<String, dynamic>? ?? {};
    for (final uid in splits.keys) {
      participantNames[uid] = _getUserDisplayName(uid);
    }

    final payerId = (e['payer'] ?? e['paidBy'] ?? '').toString();
    final enrichedExpense = {
      ...e,
      'participantNames': participantNames,
      'payerName': _getUserDisplayName(payerId),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          houseId: _houseId!,
          expenseId: expenseId,
          initialExpense: enrichedExpense,
        ),
      ),
    );
  }

  Map<String, double> _computeNetBalances() {
    return computeNetBalances(
      _expenses,
      _settlements,
      _currentUserId,
      _memberIds,
    );
  }

  String _getUserDisplayName(String uid) {
    if (uid == _currentUserId) return 'Bạn';
    final profile = _userProfiles[uid];
    if (profile?.name != null) return profile!.name;
    // Fallback: hiển thị UID ngắn gọn
    return uid.length > 6 ? 'User ${uid.substring(0, 6)}' : 'User $uid';
  }

  String _getUserInitial(String uid) {
    final name = _getUserDisplayName(uid);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Lấy tiêu đề expense mới nhất liên quan đến cặp payer-debtor
  String _findLatestExpenseTitle({
    required String payerId,
    required String debtorId,
  }) {
    for (final e in _expenses) {
      final expensePayer = (e['paidBy'] ?? e['payer'] ?? '').toString();
      final splits = e['splits'] as Map<String, dynamic>? ?? {};
      if (expensePayer == payerId && splits.containsKey(debtorId)) {
        return (e['title'] as String?)?.trim().isNotEmpty == true
            ? (e['title'] as String)
            : 'Chi phí chung';
      }
      if (expensePayer == debtorId && splits.containsKey(payerId)) {
        return (e['title'] as String?)?.trim().isNotEmpty == true
            ? (e['title'] as String)
            : 'Chi phí chung';
      }
    }
    return 'Chi phí chung';
  }
}
