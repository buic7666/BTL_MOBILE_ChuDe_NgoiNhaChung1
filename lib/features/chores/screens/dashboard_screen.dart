import 'package:flutter/material.dart';

import '../widgets/feature_card.dart';
import '../widgets/progress_bar.dart';

import 'create_task_screen.dart';
import 'assign_screen.dart';
import 'complete_screen.dart';
import 'ranking_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ===== HEADER =====
              const Center(
                child: Text(
                  "Quản lý việc nhà",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D4AF3),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "• Chores Wheel",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8AAC),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// ===== WELCOME CARD (FULL WIDTH) =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7A74F9),
                      Color(0xFF8E7CF6),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chào mừng trở lại! 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Theo dõi tiến độ 4 chức năng chính.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// ===== THỐNG KÊ TUẦN =====
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 4),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Thống kê Tuần này",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F2F4F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(
                          child:
                              _StatItem(title: "Việc nhà", value: "12"),
                        ),
                        _Divider(),
                        Expanded(
                          child: _StatItem(title: "Tới hạn", value: "3"),
                        ),
                        _Divider(),
                        Expanded(
                          child:
                              _StatItem(title: "Điểm tháng", value: "48"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// ===== PROGRESS =====
              const Text(
                "Tiến độ tuần này  68%",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B5F7D),
                ),
              ),
              const SizedBox(height: 6),
              const CustomProgressBar(
                value: 0.68,
                height: 6,
              ),

              const SizedBox(height: 20),

              /// ===== FEATURES =====
              const Text(
                "Chức năng chính",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B5F7D),
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  FeatureCard(
                    icon:
                        const Text("📝", style: TextStyle(fontSize: 28)),
                    title: "Tạo Việc Nhà",
                    desc: "Đã tạo: 12 task",
                    progress: 0.75,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTaskScreen(),
                      ),
                    ),
                  ),
                  FeatureCard(
                    icon:
                        const Text("🔄", style: TextStyle(fontSize: 28)),
                    title: "Phân Công",
                    desc: "Lượt phân công: 8",
                    progress: 0.5,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignScreen(),
                      ),
                    ),
                  ),
                  FeatureCard(
                    icon:
                        const Text("✔️", style: TextStyle(fontSize: 28)),
                    title: "Hoàn Thành",
                    desc: "Đã hoàn thành: 6",
                    progress: 0.6,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompleteScreen(),
                      ),
                    ),
                  ),
                  FeatureCard(
                    icon:
                        const Text("🏆", style: TextStyle(fontSize: 28)),
                    title: "Bảng Xếp Hạng",
                    desc: "Top tuần: Hằng – 25 điểm",
                    progress: 0.9,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RankingScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== STAT ITEM =====
class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F2F4F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8AAC),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: const Color(0xFFE0E2F1),
    );
  }
}
