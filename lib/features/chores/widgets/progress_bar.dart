import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color backgroundColor;
  final Color valueColor;

  const CustomProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.backgroundColor = const Color(0xFFE6E8FF),
    this.valueColor = const Color(0xFF5B6CFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(valueColor),
      ),
    );
  }
}
