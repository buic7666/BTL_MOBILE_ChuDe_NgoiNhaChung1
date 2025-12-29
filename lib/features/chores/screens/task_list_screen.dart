import 'package:flutter/material.dart';
import '../../../core/services/chore_service.dart';
import '../models/chore.dart';

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
                                          'Trạng thái: ${c.isCompleted ? 'Đã xong' : 'Chưa xong'} • +${c.points} điểm',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5B5F7D),
                                          ),
                                        ),
                                      ],
                                    ),
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
