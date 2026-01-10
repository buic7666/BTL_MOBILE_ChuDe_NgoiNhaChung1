import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

class AddShoppingItemDialog extends StatefulWidget {
  final Function(ShoppingItem) onAddItem;

  const AddShoppingItemDialog({
    Key? key,
    required this.onAddItem,
  }) : super(key: key);

  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _suggestions = ['Dầu ăn', 'Gạo', 'Giấy vệ sinh'];

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên mục')),
      );
      return;
    }

    final newItem = ShoppingItem(
      id: '', // Firestore sẽ tạo id
      name: _itemNameController.text,
      quantity: _quantityController.text.isEmpty ? '1' : _quantityController.text,
      assignedTo: 'Chưa phân công',
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    widget.onAddItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.purple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thêm đồ cần mua',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Hãy nhập tên đồ cần mua ở phía dưới',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Item Name
              const Text(
                'TÊN MỤC ĐỒ *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  hintText: 'VD: Nước mắm, giấy STS...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // GHI CHÚ
              const Text(
                'GHI CHÚ (TUỲ CHỌN)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '📝 5G lung, hàng yêu thích...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Số lượng
              const Text(
                'Số lượng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Gợi ý
              const Text(
                'Gợi ý:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () {
                      _itemNameController.text = suggestion;
                    },
                    child: Chip(
                      label: Text(suggestion),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade800),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 6),
                          Text('Thêm mục'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
