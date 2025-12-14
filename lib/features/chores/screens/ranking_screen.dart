import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ranking = [
      {"name": "Hằng", "point": 62},
      {"name": "An", "point": 48},
      {"name": "Bình", "point": 36},
      {"name": "Nam", "point": 22},
    ];

    final int maxPoint = ranking.first["point"] as int;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🏆 Danh sách xếp hạng
            ...ranking.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final int point = user["point"] as int;
              final double progress = point / maxPoint;

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
                          "#${index + 1} - ${user["name"]}",
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D6DF6), Color(0xFF8E7CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "🏆 Thành viên tích cực tháng: Hằng",
                textAlign: TextAlign.center,
                style: TextStyle(
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
