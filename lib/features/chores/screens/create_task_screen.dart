import 'package:flutter/material.dart';
import '../../../core/services/chore_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController assigneeController = TextEditingController();

  String frequency = "Hằng ngày";
  int points = 1;

  @override
  void dispose() {
    taskNameController.dispose();
    assigneeController.dispose();
    super.dispose();
  }

  Future<void> createTask() async {
    final choreService = ChoreService();
    final houseId = await choreService.currentUserHouseId();
    if (houseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có nhà. Vui lòng tham gia/tạo nhà.')),
      );
      return;
    }

    final assigneeName = assigneeController.text.trim().isEmpty
        ? 'Chưa phân công'
        : assigneeController.text.trim();
    final title = taskNameController.text.trim().isEmpty
        ? 'Chưa đặt tên'
        : taskNameController.text.trim();

    final success = await choreService.addChore(
      houseId: houseId,
      title: title,
      assignedToUid: null,
      assignedToName: assigneeName,
      frequency: frequency,
      points: points,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Đã tạo việc: +$points điểm khi hoàn thành')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo việc thất bại. Thử lại sau.')),
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F1F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      "Tạo Việc Nhà",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F5BFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Tên việc:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F2F4F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: taskNameController,
                    decoration: _inputDecoration("VD: Đổ rác"),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Chu kỳ lặp",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F2F4F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: _inputDecoration(""),
                    items: const [
                      DropdownMenuItem(value: "Hằng ngày", child: Text("Hằng ngày")),
                      DropdownMenuItem(value: "Hằng tuần", child: Text("Hằng tuần")),
                      DropdownMenuItem(value: "Hằng tháng", child: Text("Hằng tháng")),
                    ],
                    onChanged: (v) => setState(() => frequency = v ?? "Hằng ngày"),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Điểm thưởng khi hoàn thành",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F2F4F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: points,
                    decoration: _inputDecoration(""),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("+1 điểm")),
                      DropdownMenuItem(value: 3, child: Text("+3 điểm")),
                      DropdownMenuItem(value: 5, child: Text("+5 điểm")),
                    ],
                    onChanged: (v) => setState(() => points = v ?? 1),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF8A7CFF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: createTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Tạo việc nhà",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF2F5BFF),
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
