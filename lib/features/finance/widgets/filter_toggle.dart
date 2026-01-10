import 'package:flutter/material.dart';

/// Widget hiển thị toggle button để chọn giữa "Ai nợ ai" và "Chi tiêu"
class FilterToggle extends StatelessWidget {
  final int selectedToggle;
  final Function(int) onToggleChanged;

  const FilterToggle({
    Key? key,
    required this.selectedToggle,
    required this.onToggleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.swap_vert, size: 20, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggleChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedToggle == 0
                      ? const Color(0xFF7C5CFF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedToggle == 0
                        ? const Color(0xFF7C5CFF)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Ai nợ ai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selectedToggle == 0
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggleChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedToggle == 1
                      ? const Color(0xFF7C5CFF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedToggle == 1
                        ? const Color(0xFF7C5CFF)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Chi tiêu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selectedToggle == 1
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
