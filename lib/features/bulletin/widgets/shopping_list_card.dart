import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import 'add_shopping_item_dialog.dart';

class ShoppingListCard extends StatelessWidget {
  final List<ShoppingItem> shoppingItems;
  final Function(ShoppingItem)? onAddItem;
  final Function(int)? onToggleItem;
  final Function(int)? onDeleteItem;
  final String? houseId;

  const ShoppingListCard({
    Key? key,
    required this.shoppingItems,
    this.onAddItem,
    this.onToggleItem,
    this.onDeleteItem,
    this.houseId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách mua sắm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${shoppingItems.length} mục',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shoppingItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Chưa có mục nào',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...shoppingItems.asMap().entries.map((entry) {
              int index = entry.key;
              ShoppingItem item = entry.value;
              return Column(
                children: [
                  ShoppingItemWidget(
                    item: item,
                    onToggle: () => onToggleItem?.call(index),
                    onDelete: () => onDeleteItem?.call(index),
                  ),
                  if (index < shoppingItems.length - 1)
                    const Divider(height: 16),
                ],
              );
            }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddShoppingItemDialog(
                      onAddItem: (ShoppingItem newItem) {
                        onAddItem?.call(newItem);
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: Text(houseId == null ? 'Cần có houseId' : 'Thêm mục mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingItemWidget extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const ShoppingItemWidget({
    Key? key,
    required this.item,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: item.isCompleted ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: item.isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration:
                      item.isCompleted ? TextDecoration.lineThrough : null,
                  color: item.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              Text(
                item.quantity,
                style: TextStyle(
                  fontSize: 13,
                  color: item.isCompleted ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.assignedTo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete?.call();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Xóa'),
            ),
          ],
        ),
      ],
    );
  }
}
