import 'package:flutter/material.dart';
import 'progress_bar.dart';

class FeatureCard extends StatelessWidget {
  final Widget icon; // ⚠️ PHẢI là Widget
  final String title;
  final String desc;
  final double progress;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Color(0x15000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF33335A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B6B85),
              ),
            ),
            const Spacer(),
            CustomProgressBar(
              value: progress,
              height: 5,
            ),
          ],
        ),
      ),
    );
  }
}
