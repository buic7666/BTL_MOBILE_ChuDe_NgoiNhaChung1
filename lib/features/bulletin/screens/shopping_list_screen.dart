import 'dart:async';
import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../widgets/shopping_list_card.dart';
import '../../../core/services/bulletin_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final String houseId;

  const ShoppingListScreen({super.key, required this.houseId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final BulletinService _service;
  StreamSubscription<List<ShoppingItem>>? _sub;
  List<ShoppingItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = BulletinService();
    _sub = _service
        .shoppingItemsStream(widget.houseId)
        .listen((event) {
      if (!mounted) return;
      setState(() {
        _items = event;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _addItem(ShoppingItem item) {
    _service.addShoppingItem(widget.houseId, item);
  }

  void _toggleItem(int index) {
    final item = _items[index];
    _service.toggleShoppingItem(widget.houseId, item);
  }

  void _deleteItem(int index) {
    final item = _items[index];
    _service.deleteShoppingItem(widget.houseId, item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách mua sắm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ShoppingListCard(
                shoppingItems: _items,
                onAddItem: _addItem,
                onToggleItem: _toggleItem,
                onDeleteItem: _deleteItem,
                houseId: widget.houseId,
              ),
            ),
    );
  }
}
