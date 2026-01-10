import 'package:flutter/material.dart';
import '../../../core/services/chore_service.dart';
import '../models/chore.dart';

class CompleteScreen extends StatefulWidget {
  const CompleteScreen({super.key, this.showPendingOnly = false});

  final bool showPendingOnly;

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  String? _houseId;
  final List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadHouseId();
  }

  Future<void> _loadHouseId() async {
    final hid = await ChoreService().currentUserHouseId();
    if (mounted) setState(() => _houseId = hid);
  }

  Future<void> _completeChore(Chore chore) async {
    if (_houseId == null) return;

    final result = await ChoreService().toggleComplete(
      houseId: _houseId!,
      chore: chore,
    );

    if (result['success'] == true && mounted) {
      final completed = result['completed'] as bool;
      if (completed) {
        final userName = result['awardedUserName'] as String?;
        final points = result['awardedPoints'] as int?;
        setState(() {
          notifications.insert(
            0,
            "${userName ?? 'User'} đã hoàn thành \"${chore.title}\" "
            "+${points ?? chore.points} điểm 🎉",
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Hoàn thành! Cộng ${points ?? chore.points} điểm cho ${userName ?? 'user'}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bỏ đánh dấu hoàn thành')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${result['error'] ?? 'Unknown'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_houseId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            "Xác nhận hoàn thành",
            style: TextStyle(
              color: Color(0xFF3D4AF3),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF3D4AF3)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          widget.showPendingOnly ? "Việc chưa xong" : "Xác nhận hoàn thành",
          style: const TextStyle(
            color: Color(0xFF3D4AF3),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3D4AF3)),
      ),
      body: StreamBuilder<List<Chore>>(
        stream: ChoreService().choresStream(_houseId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Chưa có việc nhà nào'),
            );
          }

          final chores = widget.showPendingOnly
              ? snapshot.data!.where((c) => !c.isCompleted).toList()
              : snapshot.data!;

          if (chores.isEmpty) {
            return const Center(
              child: Text('Không có việc cần làm'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🔔 Thông báo hoàn thành
              ...notifications.map(
                (n) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D6DF6), Color(0xFF8E7CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    n,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              /// 📋 Danh sách chores từ Firebase
              ...chores.map((chore) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Tiêu đề + trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chore.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: chore.isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2ECC71),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chore.isCompleted ? "DONE" : "TODO",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text("Điểm thưởng: +${chore.points} điểm"),
                      if (chore.awarded)
                        const Text(
                          "✓ Đã nhận điểm",
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 14),

                      /// Nút hoàn thành
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _completeChore(chore),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: chore.isCompleted
                                ? const Color(0xFFB7B7E6)
                                : const Color(0xFF6D6DF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            chore.isCompleted ? "Bỏ hoàn thành" : "Hoàn thành",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
