import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/chore_service.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/feature_card.dart';
import '../widgets/progress_bar.dart';

import 'create_task_screen.dart';
import 'assign_screen.dart';
import 'complete_screen.dart';
import 'ranking_screen.dart';
import 'task_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Map<String, dynamic>> _loadStats() async {
    final houseId = await ChoreService().currentUserHouseId();
    if (houseId == null) {
      return {'totalChores': 0, 'overdueCount': 0, 'userPoints': 0, 'completedCount': 0};
    }

    try {
      // Lấy danh sách chores
      final choresSnap = await FirebaseFirestore.instance
          .collection('houses')
          .doc(houseId)
          .collection('chores')
          .get();

      final chores = choresSnap.docs;
      final now = DateTime.now();
      
      // Đếm công việc tới hạn (dueDate <= hôm nay và chưa hoàn thành)
      final overdueCount = chores.where((doc) {
        final dueDate = (doc.data()['dueDate'] as Timestamp?)?.toDate();
        final isCompleted = doc.data()['completed'] as bool? ?? false;
        return dueDate != null && dueDate.isBefore(now) && !isCompleted;
      }).length;

      // Đếm công việc đã hoàn thành
      final completedCount = chores.where((doc) => doc.data()['completed'] as bool? ?? false).length;

      // Lấy điểm của user hiện tại
      final uid = AuthService().currentFirebaseUser?.uid;
      int userPoints = 0;
      if (uid != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          userPoints = userDoc.data()?['points'] as int? ?? 0;
        } catch (e) {
          userPoints = 0;
        }
      }

      return {
        'totalChores': chores.length,
        'overdueCount': overdueCount,
        'userPoints': userPoints,
        'completedCount': completedCount,
      };
    } catch (e) {
      print('Error loading stats: $e');
      return {'totalChores': 0, 'overdueCount': 0, 'userPoints': 0, 'completedCount': 0};
    }
  }

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

              /// ===== WELCOME CARD =====
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

              /// ===== THỐNG KÊ TUẦN (REAL-TIME) =====
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskListScreen(
                      taskName: "Tổng hợp việc nhà",
                      frequency: "Hằng tuần",
                      assignee: "Cả gia đình",
                    ),
                  ),
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _loadStats(),
                  builder: (context, snapshot) {
                    final totalChores = snapshot.data?['totalChores'] ?? 0;
                    final overdueCount = snapshot.data?['overdueCount'] ?? 0;
                    final userPoints = snapshot.data?['userPoints'] ?? 0;
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                            children: [
                              Expanded(
                                child: _StatItem(
                                    title: "Việc nhà", value: totalChores.toString()),
                              ),
                              const _Divider(),
                              Expanded(
                                child: _StatItem(
                                    title: "Tới hạn", value: overdueCount.toString()),
                              ),
                              const _Divider(),
                              Expanded(
                                child: _StatItem(
                                    title: "Điểm tháng", value: userPoints.toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              /// ===== PROGRESS =====
              FutureBuilder<Map<String, dynamic>>(
                future: _loadStats(),
                builder: (context, snapshot) {
                  final completedCount = snapshot.data?['completedCount'] ?? 0;
                  final totalChores = snapshot.data?['totalChores'] ?? 0;
                  final progress = totalChores > 0 ? completedCount / totalChores : 0.0;
                  final progressPercent = (progress * 100).toStringAsFixed(0);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tiến độ tuần này  $progressPercent%",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B5F7D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomProgressBar(
                        value: progress,
                        height: 6,
                      ),
                    ],
                  );
                },
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
                  FutureBuilder<Map<String, dynamic>>(
                    future: _loadStats(),
                    builder: (context, snapshot) {
                      final totalChores = snapshot.data?['totalChores'] ?? 0;
                      return FeatureCard(
                        icon: const Text("📝", style: TextStyle(fontSize: 28)),
                        title: "Tạo Việc Nhà",
                        desc: "Đã tạo: $totalChores task",
                        progress: 0.75,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTaskScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: const Text("🔄", style: TextStyle(fontSize: 28)),
                    title: "Phân Công",
                    desc: "Lượt phân công: Auto",
                    progress: 0.5,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignScreen(),
                      ),
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _loadStats(),
                    builder: (context, snapshot) {
                      final completedCount = snapshot.data?['completedCount'] ?? 0;
                      return FeatureCard(
                        icon: const Text("✔️", style: TextStyle(fontSize: 28)),
                        title: "Hoàn Thành",
                        desc: "Đã hoàn thành: $completedCount",
                        progress: 0.6,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompleteScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: const Text("🏆", style: TextStyle(fontSize: 28)),
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
