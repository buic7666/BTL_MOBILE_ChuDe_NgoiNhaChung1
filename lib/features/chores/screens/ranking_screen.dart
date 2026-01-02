import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/chore_service.dart';
import '../../../core/services/house_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    final houseId = await ChoreService().currentUserHouseId();
    if (houseId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final members = await HouseService().getHouseMembers(houseId);
      if (members.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final scoreMap = <String, int>{};

      // Firestore whereIn giới hạn 10, chia batch
      for (int i = 0; i < members.length; i += 10) {
        final batchIds = members.skip(i).take(10).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final name = data['name'] as String? ?? 'Không xác định';
          final points = (data['points'] as num?)?.toInt() ?? 0;
          scoreMap[name] = (scoreMap[name] ?? 0) + points;
        }
      }

      final rankingList = scoreMap.entries
          .map((e) => {'name': e.key, 'point': e.value})
          .toList();
      rankingList.sort((a, b) => (b['point'] as int).compareTo(a['point'] as int));

      if (mounted) {
        setState(() {
          ranking = rankingList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bảng xếp hạng: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int maxPoint = ranking.isNotEmpty ? (ranking.first["point"] as int) : 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bảng Xếp Hạng",
          style: TextStyle(
            color: Color(0xFF3D4AF3),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3D4AF3)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ranking.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu xếp hạng'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// 🏆 Danh sách xếp hạng
                      ...ranking.asMap().entries.map((entry) {
                        final index = entry.key;
                        final person = entry.value;
                        final int point = person["point"] as int;
                        final double progress = point / (maxPoint > 0 ? maxPoint : 1);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFF6D6DF6),
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Tên + điểm + top badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "#${index + 1} - ${person["name"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "$point điểm",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (index < 3) ...[
                              const SizedBox(width: 8),
                              _topBadge(index),
                            ]
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Thanh tiến trình
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation(
                          const Color(0xFF6D6DF6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

                      const SizedBox(height: 12),

                      /// 🏅 Thành viên tích cực
                      if (ranking.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D6DF6), Color(0xFF8E7CF6)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            "🏆 Thành viên tích cực tháng: ${ranking.first['name']}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
    );
  }

  /// 🎖 Badge Top
  static Widget _topBadge(int index) {
    final colors = [
      const Color(0xFFFFC107), // Top 1
      const Color(0xFFB0BEC5), // Top 2
      const Color(0xFFCD7F32), // Top 3
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[index],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Top ${index + 1}",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
