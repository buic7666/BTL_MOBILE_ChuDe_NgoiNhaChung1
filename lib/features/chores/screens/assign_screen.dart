import 'package:flutter/material.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  final List<String> tasks = [
    "Đổ rác",
    "Lau nhà",
    "Vệ sinh tủ lạnh",
  ];

  final List<String> members = [
    "An",
    "Bình",
    "Hằng",
  ];

  int weekIndex = 1;
  Map<String, String> currentAssign = {};
  final List<String> history = [];

  void rotateAssign() {
    setState(() {
      currentAssign.clear();

      for (int i = 0; i < tasks.length; i++) {
        final assignee = members[(weekIndex - 1 + i) % members.length];
        currentAssign[tasks[i]] = assignee;

        history.insert(
          0,
          "Tuần $weekIndex: ${tasks[i]} → $assignee",
        );
      }

      weekIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Phân công tự động",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5B6CFF),
                Color(0xFF8A7CFF),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(
            title: "Danh sách việc nhà",
            icon: Icons.list_alt,
            children: tasks.map((e) => _bulletText(e)).toList(),
          ),
          _infoCard(
            title: "Danh sách thành viên",
            icon: Icons.people,
            children: members.map((e) => _bulletText(e)).toList(),
          ),

          const SizedBox(height: 8),

          // ===== ROTATE BUTTON =====
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: rotateAssign,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5B6CFF),
                      Color(0xFF8A7CFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Xoay vòng phân công tuần",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _infoCard(
            title: "Phân công tuần này",
            icon: Icons.calendar_month,
            children: currentAssign.isEmpty
                ? [
                    const Text(
                      "Chưa có dữ liệu",
                      style: TextStyle(color: Color(0xFF8A8AAC)),
                    )
                  ]
                : currentAssign.entries
                    .map(
                      (e) => Row(
                        children: [
                          Expanded(child: Text("• ${e.key}")),
                          const Icon(
                            Icons.arrow_right_alt,
                            color: Color(0xFF5B6CFF),
                          ),
                          Text(
                            e.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),

          _infoCard(
            title: "Lịch sử phân công",
            icon: Icons.history,
            children: history.isEmpty
                ? [
                    const Text(
                      "Chưa có lịch sử",
                      style: TextStyle(color: Color(0xFF8A8AAC)),
                    )
                  ]
                : history
                    .map(
                      (e) => Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Color(0xFF5B6CFF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ===== CARD =====
  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5B6CFF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F2F4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: e,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletText(String text) {
    return Text(
      "• $text",
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF5B5F7D),
      ),
    );
  }
}
