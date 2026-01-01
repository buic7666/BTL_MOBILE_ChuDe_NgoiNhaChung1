import 'package:flutter/material.dart';
import '../../../core/services/chore_service.dart';
import '../models/chore.dart';
class TaskListScreen extends StatefulWidget {
class TaskListScreen extends StatelessWidget {
  final String taskName;
  final String frequency;
  final String assignee;

  const TaskListScreen({
    super.key,
    required this.taskName,
    required this.frequency,
    required this.assignee,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  void _showDeleteDialog(BuildContext context, String houseId, Chore chore) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Bạn có chắc muốn xóa "${chore.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ChoreService().deleteChore(
                houseId: houseId,
                choreId: chore.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✓ Đã xóa công việc' : 'Xóa thất bại'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String houseId, Chore chore) {
    final titleCtrl = TextEditingController(text: chore.title);
    final nameCtrl = TextEditingController(text: chore.assignedToName ?? '');
    String frequency = chore.frequency ?? 'Hằng ngày';
    int points = chore.points;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa công việc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Người thực hiện',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(
                  labelText: 'Chu kỳ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Hằng ngày', child: Text('Hằng ngày')),
                  DropdownMenuItem(value: 'Hằng tuần', child: Text('Hằng tuần')),
                  DropdownMenuItem(value: 'Hằng tháng', child: Text('Hằng tháng')),
                ],
                onChanged: (val) => frequency = val ?? 'Hằng ngày',
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Điểm thưởng',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => points = int.tryParse(val) ?? 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ChoreService().updateChore(
                houseId: houseId,
                choreId: chore.id,
                title: titleCtrl.text.trim(),
                assignedToName: nameCtrl.text.trim(),
                frequency: frequency,
                points: points,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✓ Đã cập nhật' : 'Cập nhật thất bại'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
              titleCtrl.dispose();
              nameCtrl.dispose();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Danh sách Task",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5CFF),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Danh sách từ Firestore
              Expanded(
                child: FutureBuilder<String?>(
                  future: ChoreService().currentUserHouseId(),
                  builder: (context, snapshot) {
                    final hid = snapshot.data;
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (hid == null) {
                      return const Center(child: Text('Chưa có nhà.'));
                    }
                    return StreamBuilder<List<Chore>>(
                      stream: ChoreService().choresStream(hid),
                      builder: (context, snap) {
                        final chores = snap.data ?? [];
                        if (chores.isEmpty) {
                          return const Center(child: Text('Chưa có việc nhà.'));
                        }
                        return ListView.separated(
                          itemCount: chores.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final c = chores[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B6CFF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2F2F4F),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Người thực hiện: ${c.assignedToName ?? '—'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5B5F7D),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Chu kỳ: ${c.frequency ?? 'Chưa đặt'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5B5F7D),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Trạng thái: ${c.isCompleted ? 'Đã xong' : 'Chưa xong'} • +${c.points} điểm',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5B5F7D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteDialog(context, hid, c);
                                      } else if (value == 'edit') {
                                        _showEditDialog(context, hid, c);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Sửa'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Xóa', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
                      child: Text(
                        "Quay lại",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
