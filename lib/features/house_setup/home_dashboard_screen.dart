import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';

// 👉 IMPORT DASHBOARD CHORES WHEEL
import '../chores/screens/dashboard_screen.dart';

class DynamicHomeScreen extends StatefulWidget {
  const DynamicHomeScreen({super.key});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // --- GIẢ LẬP DỮ LIỆU ĐỘNG ---
    final String userName = "Khánh";
    final bool hasChoreToday = true;
    final String currentChore = "Đổ rác & Lau bếp";
    final double myDebt = -50000;
    final double othersOweMe = 120000;
    final int shoppingItemCount = 3;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _buildBody(
        _selectedIndex,
        userName,
        hasChoreToday,
        currentChore,
        myDebt,
        othersOweMe,
        shoppingItemCount,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            // 👉 TAB "VIỆC NHÀ" → MỞ DASHBOARD CHORES WHEEL
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
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

  Widget _buildBody(
    int index,
    String userName,
    bool hasChoreToday,
    String currentChore,
    double myDebt,
    double othersOweMe,
    int shoppingItemCount,
  ) {
    switch (index) {
      case 0:
        return _buildHomeTab(userName, hasChoreToday, currentChore, myDebt, othersOweMe, shoppingItemCount);
      case 2:
        return _buildFinanceTab(myDebt, othersOweMe);
      case 3:
        return _buildInfoTab();
      default:
        return _buildHomeTab(userName, hasChoreToday, currentChore, myDebt, othersOweMe, shoppingItemCount);
    }
  }

  // ================= TAB HOME =================
  Widget _buildHomeTab(
    String userName,
    bool hasChoreToday,
    String currentChore,
    double myDebt,
    double othersOweMe,
    int shoppingItemCount,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName),
            const SizedBox(height: 24),
            const Text("Việc nhà hôm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            hasChoreToday ? _buildActiveChoreCard(currentChore) : _buildFreeStateCard(),
            const SizedBox(height: 24),
            const Text("Ví của tôi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildFinanceCard("Bạn đang nợ", myDebt, isNegative: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildFinanceCard("Bạn được trả", othersOweMe, isNegative: false)),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Đang diễn ra", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildShoppingSummary(shoppingItemCount),
          ],
        ),
      ),
    );
  }

  // ================= TAB FINANCE =================
  Widget _buildFinanceTab(double myDebt, double othersOweMe) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quản lý Tài chính", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text("Bạn đang nợ: ${formatter.format(myDebt.abs())}", style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            Text("Bạn được trả: ${formatter.format(othersOweMe)}", style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  // ================= TAB INFO =================
  Widget _buildInfoTab() {
    return const SafeArea(
      child: Center(
        child: Text("Thông tin chung", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ================= WIDGETS CON =================

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Chào buổi sáng ☀️", style: TextStyle(color: Colors.grey)),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        const CircleAvatar(radius: 22, backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11")),
      ],
    );
  }

  Widget _buildActiveChoreCard(String choreName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4834D4)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Lượt của bạn", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(choreName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
          child: const Text("Đánh dấu đã xong"),
        )
      ]),
    );
  }

  Widget _buildFreeStateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Text("Hôm nay bạn không có việc 🎉"),
    );
  }

  Widget _buildFinanceCard(String title, double amount, {required bool isNegative}) {
    final color = isNegative ? Colors.red : Colors.green;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Text(formatter.format(amount.abs()), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildShoppingSummary(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text("$count món cần mua"),
    );
  }
}
