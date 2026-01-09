import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../chores/screens/dashboard_screen.dart';
import '../chores/screens/complete_screen.dart';
import '../bulletin/screens/house_bulletin_screen.dart';
import '../bulletin/screens/shopping_list_screen.dart';
import '../finance/screens/finance_main_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/house_service.dart';
import '../../core/services/bulletin_service.dart';
import '../../core/services/chore_service.dart';
import '../../core/services/finance_service.dart';
import '../finance/models/finance_logic.dart';
import 'home_screen.dart';
import '../chores/models/chore.dart';

class DynamicHomeScreen extends StatefulWidget {
  const DynamicHomeScreen({super.key});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  int _selectedIndex = 0;

  bool _isLoading = true;
  String _userName = '';
  String _houseName = '';
  String _houseCode = '';
  String? _houseId;
  String? _currentUserId;
  double _myDebt = 0;
  double _othersOweMe = 0;
  int _shoppingItemCount = 0; // số món chưa hoàn thành
  bool _hasChoreToday = false;
  String _currentChore = 'Không có việc nhà hôm nay';

  final List<Map<String, dynamic>> _expenses = [];
  final Map<String, double> _settlements = {};
  List<String> _memberIds = [];
  FinanceService? _financeService;

  StreamSubscription? _shoppingStreamSub;
  StreamSubscription<List<Chore>>? _choreStreamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _expenseStreamSub;
  StreamSubscription<Map<String, double>>? _settlementStreamSub;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final auth = AuthService();
    final houseService = HouseService();

    final userProfile = await auth.getCurrentUser();
    final userName = userProfile?.name ?? userProfile?.email ?? 'Người dùng';
    final uid = auth.currentFirebaseUser?.uid;

    bool hasHouse = false;
    String houseName = 'Nhà của bạn';
    String houseCode = '';
    String? houseId;

    if (uid != null) {
      _currentUserId = uid;
      hasHouse = await houseService.hasHouse(uid);
      if (hasHouse) {
        houseName = await houseService.getHouseName(uid) ?? 'Nhà của bạn';
        houseCode = await houseService.getHouseCode(uid) ?? '';
        houseId = await houseService.getHouseId(uid);
      }
    }

    if (!mounted) return;
    setState(() {
      _userName = userName;
      _houseName = houseName;
      _houseCode = houseCode;
      _hasChoreToday = hasHouse ? _hasChoreToday : false;
      _currentChore = _hasChoreToday
          ? _currentChore
          : 'Không có việc nhà hôm nay';
      _houseId = houseId;
      _myDebt = _myDebt;
      _othersOweMe = _othersOweMe;
      _shoppingItemCount = _shoppingItemCount;
      _isLoading = false;
    });

    // Đăng ký stream để đếm số món cần mua (chưa hoàn thành)
    _subscribeShoppingCount();
    _subscribeChorePreview();
    _subscribeFinanceData();
  }

  void _subscribeFinanceData() {
    _expenseStreamSub?.cancel();
    _settlementStreamSub?.cancel();

    final hid = _houseId;
    if (hid == null) return;

    _financeService = FinanceService(houseId: hid);

    // Load members first
    HouseService().houseMembersStream(hid).listen((memberIds) {
      if (!mounted) return;
      setState(() {
        _memberIds = memberIds;
      });
    });

    // Listen to expenses
    _expenseStreamSub = _financeService!.expensesStream().listen((items) {
      if (!mounted) return;
      setState(() {
        _expenses
          ..clear()
          ..addAll(items);
        _updateFinanceData();
      });
    });

    // Listen to settlements
    _settlementStreamSub = _financeService!.settlementsStream().listen((m) {
      if (!mounted) return;
      setState(() {
        _settlements
          ..clear()
          ..addAll(m);
        _updateFinanceData();
      });
    });
  }

  void _updateFinanceData() {
    if (_currentUserId == null) return;

    final net = computeNetBalances(
      _expenses,
      _settlements,
      _currentUserId,
      _memberIds,
    );

    final totalOweYou = net.entries
        .where((e) => e.key != _currentUserId && e.value > 0.5)
        .fold(0.0, (p, e) => p + e.value);
    final totalYouOwe = net.entries
        .where((e) => e.key != _currentUserId && e.value < -0.5)
        .fold(0.0, (p, e) => p + e.value.abs());

    setState(() {
      _myDebt = totalYouOwe;
      _othersOweMe = totalOweYou;
    });
  }

  void _subscribeShoppingCount() {
    _shoppingStreamSub?.cancel();
    final hid = _houseId;
    if (hid == null) return;
    _shoppingStreamSub = BulletinService().shoppingItemsStream(hid).listen((items) {
      if (!mounted) return;
      final notDone = items.where((e) => !e.isCompleted).length;
      setState(() {
        _shoppingItemCount = notDone;
      });
    });
  }

  void _subscribeChorePreview() {
    _choreStreamSub?.cancel();
    final hid = _houseId;
    if (hid == null) return;

    _choreStreamSub = ChoreService().choresStream(hid).listen((chores) {
      if (!mounted) return;
      final pending = chores.where((c) => !c.isCompleted).toList()
        ..sort((a, b) {
          final aDue = a.dueDate ?? a.createdAt;
          final bDue = b.dueDate ?? b.createdAt;
          return aDue.compareTo(bDue);
        });

      setState(() {
        _hasChoreToday = pending.isNotEmpty;
        _currentChore = pending.isNotEmpty
            ? pending.first.title
            : 'Không có việc nhà hôm nay';
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trang chủ',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                // Đăng xuất và quay về màn hình Home (đăng nhập/đăng ký)
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accentPurple,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cleaning_services_outlined),
            activeIcon: Icon(Icons.cleaning_services),
            label: 'Việc nhà',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Tài chính',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Thông tin',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const DashboardScreen();
      case 2:
        return const FinanceMainScreen();
      case 3:
        return const HouseBulletinScreen();
      default:
        return _buildHomeTab();
    }
  }

  // ================= TAB HOME =================
  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(_userName, _houseName, _houseCode),
            const SizedBox(height: 24),
            _buildChoreSection(),
            const SizedBox(height: 24),
            const Text(
              "Ví của tôi",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    "Bạn đang nợ",
                    _myDebt,
                    isNegative: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinanceCard(
                    "Bạn được trả",
                    _othersOweMe,
                    isNegative: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Đang diễn ra",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildShoppingSummary(_shoppingItemCount),
          ],
        ),
      ),
    );
  }
  // ================= WIDGETS CON =================
  Widget _buildHeader(String name, String houseName, String houseCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chào buổi sáng, ☀️",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              houseName,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (houseCode.isNotEmpty)
              Text(
                'Mã nhà: $houseCode',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentPurple, width: 2),
          ),
          child: const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11"),
          ),
        ),
      ],
    );
  }

  Widget _buildChoreSummary(int pending) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CompleteScreen(showPendingOnly: true),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pending > 0 ? Colors.orange[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                pending > 0 ? Icons.cleaning_services : Icons.weekend,
                color: pending > 0 ? Colors.orange : Colors.green,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending > 0
                        ? "$pending việc chưa hoàn thành"
                        : "Bạn đang rảnh!",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    pending > 0
                        ? "Nhấn để xem và hoàn thành"
                        : "Không có việc nào hôm nay",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChoreSection() {
    // Lấy houseId từ state hoặc từ service để đảm bảo luôn có giá trị
    final Future<String?> houseFuture = _houseId != null
        ? Future.value(_houseId)
        : ChoreService().currentUserHouseId();

    return FutureBuilder<String?>(
      future: houseFuture,
      builder: (context, houseSnap) {
        if (houseSnap.connectionState == ConnectionState.waiting) {
          return _buildChoreSummary(0);
        }

        final hid = houseSnap.data;
        if (hid == null) {
          return _buildChoreSummary(0);
        }

        // Cập nhật _houseId nếu chưa có để tránh gọi lại
        if (_houseId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _houseId = hid);
          });
        }

        return StreamBuilder<List<Chore>>(
          stream: ChoreService().choresStream(hid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildChoreSummary(0);
            }
            final chores = snap.data ?? [];
            final pending = chores.where((c) => !c.isCompleted).length;
            return _buildChoreSummary(pending);
          },
        );
      },
    );
  }

  Widget _buildFinanceCard(
    String title,
    double amount, {
    required bool isNegative,
  }) {
    final color = isNegative ? AppColors.error : AppColors.success;
    final icon = isNegative ? Icons.arrow_outward : Icons.arrow_downward;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount.abs()),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingSummary(int count) {
    return InkWell(
      onTap: () {
        if (_houseId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingListScreen(houseId: _houseId!),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count món cần mua",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "Nhấn để xem danh sách",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shoppingStreamSub?.cancel();
    _choreStreamSub?.cancel();
    _expenseStreamSub?.cancel();
    _settlementStreamSub?.cancel();
    super.dispose();
  }
}

