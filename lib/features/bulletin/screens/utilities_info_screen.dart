import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../../../core/services/house_service.dart';
import '../../../core/services/bulletin_service.dart';
import '../models/utility.dart';

class UtilitiesInfoScreen extends StatefulWidget {
  const UtilitiesInfoScreen({super.key});

  @override
  State<UtilitiesInfoScreen> createState() => _UtilitiesInfoScreenState();
}

class _UtilitiesInfoScreenState extends State<UtilitiesInfoScreen> {
  List<Utility> utilities = [];
  StreamSubscription<List<Utility>>? _utilitiesSub;
  bool _loading = true;
  String? _houseId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final auth = AuthService();
    final houseService = HouseService();
    final uid = auth.currentFirebaseUser?.uid;

    String? houseId;
    if (uid != null) {
      houseId = await houseService.getHouseId(uid);
    }

    if (!mounted) return;

    if (houseId != null) {
      setState(() => _houseId = houseId);
      _utilitiesSub?.cancel();
      _utilitiesSub = BulletinService().utilitiesStream(houseId).listen((items) {
        if (!mounted) return;
        setState(() {
          utilities = items;
          _loading = false;
        });
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _utilitiesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Thông tin Tiện ích',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Thông tin Tiện ích',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_houseId != null)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () => _showAddUtilityDialog(),
              tooltip: 'Thêm tiện ích',
            ),
        ],
      ),
      body: utilities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông tin tiện ích',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_houseId != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddUtilityDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tiện ích đầu tiên'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: utilities.map((util) {
                  return _buildUtilityCard(util);
                }).toList(),
              ),
            ),
    );
  }

  Future<void> _showAddUtilityDialog() async {
    if (_houseId == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    UtilityType selectedType = UtilityType.other;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm tiện ích mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tiện ích',
                    hintText: 'VD: Điện, Nước, Internet...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UtilityType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại tiện ích',
                    border: OutlineInputBorder(),
                  ),
                  items: UtilityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getUtilityTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'VD: Thanh toán hàng tháng',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá',
                    hintText: 'VD: 200.000đ/tháng',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                final price = priceController.text.trim();
                final dialogContext = context;

                if (name.isEmpty || description.isEmpty || price.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final now = DateTime.now();
                  final utility = Utility(
                    id: '',
                    name: name,
                    description: description,
                    price: price,
                    type: selectedType,
                    icon: _getUtilityIcon(selectedType),
                    color: _getUtilityColor(selectedType),
                    createdAt: now,
                    updatedAt: now,
                  );
                  await BulletinService().addUtility(_houseId!, utility);
                  
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm tiện ích mới'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  String _getUtilityTypeName(UtilityType type) {
    switch (type) {
      case UtilityType.wifi:
        return 'WiFi';
      case UtilityType.electricity:
        return 'Điện';
      case UtilityType.water:
        return 'Nước';
      case UtilityType.cleaning:
        return 'Vệ sinh';
      case UtilityType.internet:
        return 'Internet';
      case UtilityType.gas:
        return 'Gas';
      case UtilityType.parking:
        return 'Gửi xe';
      case UtilityType.other:
        return 'Khác';
    }
  }

  IconData _getUtilityIcon(UtilityType type) {
    switch (type) {
      case UtilityType.wifi:
        return Icons.wifi;
      case UtilityType.electricity:
        return Icons.bolt;
      case UtilityType.water:
        return Icons.water_drop;
      case UtilityType.cleaning:
        return Icons.cleaning_services;
      case UtilityType.internet:
        return Icons.language;
      case UtilityType.gas:
        return Icons.local_fire_department;
      case UtilityType.parking:
        return Icons.local_parking;
      case UtilityType.other:
        return Icons.more_horiz;
    }
  }

  Color _getUtilityColor(UtilityType type) {
    switch (type) {
      case UtilityType.wifi:
        return Colors.blue;
      case UtilityType.electricity:
        return Colors.amber;
      case UtilityType.water:
        return Colors.lightBlue;
      case UtilityType.cleaning:
        return Colors.green;
      case UtilityType.internet:
        return Colors.purple;
      case UtilityType.gas:
        return Colors.orange;
      case UtilityType.parking:
        return Colors.teal;
      case UtilityType.other:
        return Colors.grey;
    }
  }

  Widget _buildUtilityCard(Utility utility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: utility.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: utility.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                utility.icon,
                color: utility.color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      utility.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      utility.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              utility.price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: utility.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
