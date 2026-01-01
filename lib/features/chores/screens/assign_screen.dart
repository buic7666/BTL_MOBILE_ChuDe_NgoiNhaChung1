import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/chore_service.dart';
import '../models/chore.dart';

class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  String? _houseId;
  List<Chore> _chores = [];
  List<Map<String, String>> _members = []; // [{uid, name}]
  List<String> _displayMemberNames = []; // tên hiển thị (gộp từ users + assignedToName)
  int weekIndex = 1;
  Map<String, String> currentAssign = {};
  final List<String> history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hid = await ChoreService().currentUserHouseId();
    if (hid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Lấy danh sách thành viên từ house (loại trùng) và map sang tên hiển thị
    final houseDoc = await FirebaseFirestore.instance.collection('houses').doc(hid).get();
    final memberIds = List<String>.from(houseDoc.data()?['members'] ?? []).toSet().toList();

    // Lấy tên từ users với fallback thân thiện
    final membersList = <Map<String, String>>[];
    for (final uid in memberIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final email = data['email'] as String?;
      final nameFromEmail = email != null && email.contains('@')
          ? email.split('@').first
          : null;
      final name = (data['name'] as String?)?.trim();

      final displayName = (name != null && name.isNotEmpty)
          ? name
          : (nameFromEmail ?? uid);

      membersList.add({'uid': uid, 'name': displayName});
    }

    // Lấy chores một lần
    final choresSnap = await FirebaseFirestore.instance
        .collection('houses')
        .doc(hid)
        .collection('chores')
        .orderBy('createdAt')
        .get();
    final choresList = choresSnap.docs.map((d) => Chore.fromJson(d.data(), d.id)).toList();

    // Tên hiển thị: gộp tên thành viên (users) + tên được nhập khi tạo việc
    final displayNamesSet = <String>{
      ...membersList.map((m) => m['name']!),
      ...choresList
          .map((c) => c.assignedToName)
          .whereType<String>()
          .where((n) => n.trim().isNotEmpty && n != 'Chưa phân công')
          .map((n) => n.trim()),
    }..removeWhere((n) => n.isEmpty);

    final displayNames = displayNamesSet.toList();
    displayNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _houseId = hid;
      _members = membersList;
      _displayMemberNames = displayNames;
      _chores = choresList;
      _loading = false;
    });
  }

  Future<void> rotateAssign() async {
    if (_houseId == null || _chores.isEmpty || _members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có đủ dữ liệu để phân công')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      currentAssign.clear();

      for (int i = 0; i < _chores.length; i++) {
        final chore = _chores[i];
        
        // Quay vòng gán cho tất cả chores - không giữ nguyên
        String assignedName;
        String assignedUid;
        
        // Tính toán index thành viên dựa trên weekIndex
        final memberIndex = (weekIndex - 1 + i) % _members.length;
        final member = _members[memberIndex];
        assignedName = member['name']!;
        assignedUid = member['uid']!;
        // Nếu chore đã có assignedToName (từ CreateTaskScreen), giữ nguyên
        // Nếu chưa có, mới dùng quay vòng
        String assignedName;
        String assignedUid;
        
        if (chore.assignedToName != null && chore.assignedToName!.isNotEmpty && chore.assignedToName != 'Chưa phân công') {
          // Giữ tên đã có
          assignedName = chore.assignedToName!;
          assignedUid = chore.assignedToUid ?? '';
        } else {
          // Quay vòng gán
          final memberIndex = (weekIndex - 1 + i) % _members.length;
          final member = _members[memberIndex];
          assignedName = member['name']!;
          assignedUid = member['uid']!;
        }

        currentAssign[chore.title] = assignedName;

        // Cập nhật assignedToUid và assignedToName trong Firestore
        final choreRef = FirebaseFirestore.instance
            .collection('houses')
            .doc(_houseId)
            .collection('chores')
            .doc(chore.id);
        batch.update(choreRef, {
          'assignedToUid': assignedUid,
          'assignedToName': assignedName,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        history.insert(
          0,
          "Tuần $weekIndex: ${chore.title} → $assignedName",
        );
      }

      // Lưu lịch sử phân công vào subcollection
      final historyRef = FirebaseFirestore.instance
          .collection('houses')
          .doc(_houseId)
          .collection('assignment_history')
          .doc();
      batch.set(historyRef, {
        'weekIndex': weekIndex,
        'assignments': currentAssign,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      // Reload chores để cập nhật UI
      await _loadData();

      weekIndex++;
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Phân công thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            children: _chores.map((c) => _bulletText(c.title)).toList(),
          ),
          _infoCard(
            title: "Danh sách thành viên",
            icon: Icons.people,
            children: _displayMemberNames.map((name) => _bulletText(name)).toList(),
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
