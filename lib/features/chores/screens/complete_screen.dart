import 'package:flutter/material.dart';

class CompleteScreen extends StatefulWidget {
  const CompleteScreen({super.key});

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  final List<Map<String, dynamic>> tasks = [
    {
      "name": "Đổ rác",
      "user": "An",
      "reward": 1,
      "total": 0,
      "done": false,
    },
    {
      "name": "Lau nhà",
      "user": "Bình",
      "reward": 3,
      "total": 0,
      "done": false,
    },
    {
      "name": "Vệ sinh tủ lạnh",
      "user": "Hằng",
      "reward": 5,
      "total": 0,
      "done": false,
    },
  ];

  final List<String> notifications = [];

  void completeTask(int index) {
    setState(() {
      tasks[index]["done"] = true;
      tasks[index]["total"] += tasks[index]["reward"];

      notifications.insert(
        0,
        "${tasks[index]["user"]} đã hoàn thành "
        "\"${tasks[index]["name"]}\" "
        "+${tasks[index]["reward"]} điểm 🎉",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
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

          /// 📋 Danh sách task
          ...tasks.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;

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
                      Text(
                        t["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: t["done"]
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t["done"] ? "DONE" : "TODO",
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
                  Text("Người làm: ${t["user"]}"),
                  Text("Điểm thưởng: +${t["reward"]} điểm"),
                  Text("Tổng điểm: ${t["total"]}"),

                  const SizedBox(height: 14),

                  /// Nút hoàn thành
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          t["done"] ? null : () => completeTask(i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D6DF6),
                        disabledBackgroundColor:
                            const Color(0xFFB7B7E6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t["done"] ? "Đã hoàn thành" : "Hoàn thành",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
