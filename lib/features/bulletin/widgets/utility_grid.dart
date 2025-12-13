import 'package:flutter/material.dart';
import '../models/utility.dart';

class UtilityGrid extends StatelessWidget {
  final List<Utility> utilities;
  final Function(int)? onUtilityTap;

  const UtilityGrid({
    Key? key,
    required this.utilities,
    this.onUtilityTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: utilities.length,
      itemBuilder: (context, index) {
        final utility = utilities[index];
        return GestureDetector(
          onTap: () => onUtilityTap?.call(index),
          child: Container(
            decoration: BoxDecoration(
              color: utility.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  utility.icon,
                  color: utility.color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  utility.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  utility.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
