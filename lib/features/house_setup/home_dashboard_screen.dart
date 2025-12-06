import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';

import '../../constants/app_colors.dart';

class DynamicHomeScreen extends StatefulWidget {
  const DynamicHomeScreen({super.key});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // --- GIẢ LẬP DỮ LIỆU ĐỘNG (Sau này lấy từ Firebase) ---
    final String userName = "Khánh";
    final bool hasChoreToday = true;
    final String currentChore = "Đổ rác & Lau bếp";
    final double myDebt = -50000;
    final double othersOweMe = 120000;
    final int shoppingItemCount = 3;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _buildBody(_selectedIndex, userName, hasChoreToday, currentChore, myDebt, othersOweMe, shoppingItemCount),
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

  Widget _buildBody(int index, String userName, bool hasChoreToday, String currentChore, 
      double myDebt, double othersOweMe, int shoppingItemCount) {
    switch (index) {
      case 0:
        return _buildHomeTab(userName, hasChoreToday, currentChore, myDebt, othersOweMe, shoppingItemCount);
      case 1:
        return _buildChoreTab();
      case 2:
        return _buildFinanceTab(myDebt, othersOweMe);
      case 3:
        return _buildInfoTab();
      default:
        return _buildHomeTab(userName, hasChoreToday, currentChore, myDebt, othersOweMe, shoppingItemCount);
    }
  }

  // TAB 1: Trang chủ (Home)
  Widget _buildHomeTab(String userName, bool hasChoreToday, String currentChore, 
      double myDebt, double othersOweMe, int shoppingItemCount) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName),
            const SizedBox(height: 24),
            const Text("Việc nhà hôm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            hasChoreToday 
                ? _buildActiveChoreCard(currentChore)
                : _buildFreeStateCard(),
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

  // TAB 2: Quản lý Việc nhà (Chore Management)
  Widget _buildChoreTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quản lý Việc nhà", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Công việc của bạn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  // Placeholder cho các công việc
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildChoreItem("Công việc ${index + 1}", "Thứ ${index + 2}"),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: Quản lý Tài chính (Finance)
  Widget _buildFinanceTab(double myDebt, double othersOweMe) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quản lý Tài chính", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildFinanceCard("Bạn đang nợ", myDebt, isNegative: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildFinanceCard("Bạn được trả", othersOweMe, isNegative: false)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Lịch sử giao dịch", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  // Placeholder cho lịch sử
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTransactionItem("Giao dịch ${index + 1}", "-50.000đ"),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 4: Thông tin chung (General Information)
  Widget _buildInfoTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thông tin chung", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            
            // Thông tin nhóm
            _buildInfoSection("Thông tin nhóm", [
              _buildInfoItemRow("Tên nhóm:", "Nhà 123 - Shared House"),
              _buildInfoItemRow("Địa chỉ:", "Số 123, Đường ABC, Quận XYZ"),
              _buildInfoItemRow("Số thành viên:", "4 người"),
            ]),
            
            const SizedBox(height: 24),
            
            // Danh sách thành viên
            _buildInfoSection("Thành viên", [
              _buildMemberItem("Khánh", "Leader", "https://i.pravatar.cc/150?img=1"),
              _buildMemberItem("An", "Thành viên", "https://i.pravatar.cc/150?img=2"),
              _buildMemberItem("Bình", "Thành viên", "https://i.pravatar.cc/150?img=3"),
              _buildMemberItem("Cường", "Thành viên", "https://i.pravatar.cc/150?img=4"),
            ]),
            
            const SizedBox(height: 24),
            
            // Thiết lập
            _buildInfoSection("Thiết lập", [
              _buildSettingItem("Thay đổi tên nhóm", Icons.edit),
              _buildSettingItem("Quản lý thành viên", Icons.group),
              _buildSettingItem("Cài đặt thông báo", Icons.notifications),
              _buildSettingItem("Về ứng dụng", Icons.info),
            ]),
          ],
        ),
      ),
    );
  }

  // Helper widget cho phần thông tin
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Helper widget cho item thông tin
  Widget _buildInfoItemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // Helper widget cho thành viên
  Widget _buildMemberItem(String name, String role, String avatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // Helper widget cho mục thiết lập
  Widget _buildSettingItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentPurple, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // Helper widget cho mục công việc
  Widget _buildChoreItem(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Checkbox(value: false, onChanged: (value) {}),
        ],
      ),
    );
  }

  // Helper widget cho mục giao dịch
  Widget _buildTransactionItem(String title, String amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
        ],
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chào buổi sáng, ☀️", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2), // Border
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accentPurple, width: 2)),
          child: const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=11"),
          ),
        )
      ],
    );
  }

  // Card khi CÓ việc nhà (Màu sắc nổi bật, thúc giục hành động)
  Widget _buildActiveChoreCard(String choreName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4834D4)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text("Lượt của bạn", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.access_time_filled, color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              const Text("19:00", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(choreName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text("Đừng để mọi người chờ nhé!", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { /* Logic Done */ },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Đánh dấu đã xong", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // Card khi KHÔNG có việc (Màu nhẹ nhàng, thư giãn)
  Widget _buildFreeStateCard() {
    return Container(
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
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: const Icon(Icons.weekend, color: Colors.green, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bạn đang rảnh!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Hôm nay không phải lượt của bạn.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Card Tài chính (Hiển thị số tiền cụ thể)
  Widget _buildFinanceCard(String title, double amount, {required bool isNegative}) {
    final color = isNegative ? AppColors.error : AppColors.success;
    final icon = isNegative ? Icons.arrow_outward : Icons.arrow_downward;
    // Format tiền việt
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            formatter.format(amount.abs()), // Lấy giá trị tuyệt đối để hiển thị
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  // Card Shopping rút gọn
  Widget _buildShoppingSummary(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.orange, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$count món cần mua", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("Nước mắm, Giấy vệ sinh...", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onPressed: () { /* Navigate to Bulletin */ },
          )
        ],
      ),
    );
  }
}
