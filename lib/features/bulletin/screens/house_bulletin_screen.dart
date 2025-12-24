import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/house_info_card.dart';
import '../widgets/utility_grid.dart';
import '../widgets/shopping_list_card.dart';
import '../models/house_info.dart';
import '../models/utility.dart';
import '../models/shopping_item.dart';
import '../../../core/services/house_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/bulletin_service.dart';
import 'rules_screen.dart';
import 'wifi_info_screen.dart';
import 'emergency_contact_screen.dart';
import 'utilities_info_screen.dart';

class HouseBulletinScreen extends StatefulWidget {
  const HouseBulletinScreen({Key? key}) : super(key: key);

  @override
  State<HouseBulletinScreen> createState() => _HouseBulletinScreenState();
}

class _HouseBulletinScreenState extends State<HouseBulletinScreen> {
  HouseInfo? houseInfo;
  late List<Utility> utilities;
  List<ShoppingItem> shoppingItems = [];
  late List<String> rules;
  bool _isLoading = true;
  String? _houseId;
  Stream<List<ShoppingItem>>? _shoppingStream;
  StreamSubscription<List<ShoppingItem>>? _shoppingSub;
  StreamSubscription<List<Utility>>? _utilitiesSub;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final auth = AuthService();
    final houseService = HouseService();

    final uid = auth.currentFirebaseUser?.uid;
    HouseInfo? fetchedHouse;
    String? houseId;
    if (uid != null) {
      fetchedHouse = await houseService.getHouseInfoForUser(uid);
      houseId = await houseService.getHouseId(uid);
    }

    // Fallback mock nếu chưa có dữ liệu nhà
    fetchedHouse ??= HouseInfo(
      id: 'house1',
      name: 'Phòng 401 - Happy House',
      inviteCode: '882910',
      address: 'Địa chỉ mẫu',
      ownerId: 'owner1',
      memberIds: const ['owner1', 'member2', 'member3', 'member4'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    houseInfo = fetchedHouse;
    _houseId = houseId ?? fetchedHouse.id;

    if (_houseId != null) {
      _shoppingStream = BulletinService().shoppingItemsStream(_houseId!);
      _shoppingSub?.cancel();
      _shoppingSub = _shoppingStream!.listen((items) {
        if (!mounted) return;
        setState(() {
          shoppingItems = items;
        });
      });
      // Subscribe to utilities; merge into defaults by id when present
      _utilitiesSub?.cancel();
      _utilitiesSub = BulletinService().utilitiesStream(_houseId!).listen((items) {
        if (!mounted) return;
        setState(() {
          if (items.isEmpty) {
            // Keep defaults
            return;
          }
          // Map incoming items into current utilities list by id
          final byId = {for (final u in items) u.id: u};
          utilities = utilities.map((u) => byId[u.id] ?? u).toList();
        });
      });
    }

    utilities = [
      Utility.wifi(price: 'Pass: 123456789'),
      Utility.sdt(price: 'Chi nháy, Công an'),
      Utility.electricSupply(price: 'Chỉ số ngày 15'),
      Utility.rules(price: 'Xem chi tiết ↓'),
    ];

    shoppingItems = [
      ShoppingItem(
        id: 'item1',
        name: 'Nước túi báí',
        quantity: '',
        assignedTo: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ShoppingItem(
        id: 'item2',
        name: 'Giấy vệ sinh',
        quantity: '',
        assignedTo: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ShoppingItem(
        id: 'item3',
        name: 'Bằng đèn',
        quantity: '',
        assignedTo: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    rules = [
      'Giữ gìn vệ sinh chung, đặc biệt là phòng khách và nhà vệ sinh',
      'Không gây tiếng ồn sau 22h đêm',
      'Chia sẻ chi phí tiện ích công bằng hàng tháng',
      'Thông báo trước khi mời khách qua đêm',
      'Dọn dẹp đồ vật cá nhân trong không gian chung',
      'Tham gia dọn dẹp chung ít nhất 1 lần/tuần',
    ];

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _shoppingSub?.cancel();
    _utilitiesSub?.cancel();
    super.dispose();
  }

  void _addShoppingItem(ShoppingItem item) {
    if (_houseId == null) return;
    BulletinService().addShoppingItem(_houseId!, item);
  }

  void _toggleShoppingItem(int index) {
    if (_houseId == null) return;
    final item = shoppingItems[index];
    BulletinService().toggleShoppingItem(_houseId!, item);
  }

  void _deleteShoppingItem(int index) {
    if (_houseId == null) return;
    final item = shoppingItems[index];
    BulletinService().deleteShoppingItem(_houseId!, item.id);
  }

  void _showRulesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RulesScreen()),
    );
  }

  void _showWiFiInfoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WiFiInfoScreen()),
    );
  }

  void _showEmergencyContactScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
    );
  }

  void _showUtilitiesInfoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UtilitiesInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HousePal - Bảng tin nhà',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (houseInfo != null) HouseInfoCard(houseInfo: houseInfo!),
              const SizedBox(height: 16),
              UtilityGrid(
                utilities: utilities,
                onUtilityTap: (index) {
                  if (index == 0) {
                    _showWiFiInfoScreen();
                  } else if (index == 1) {
                    _showEmergencyContactScreen();
                  } else if (index == 2) {
                    _showUtilitiesInfoScreen();
                  } else if (index == 3) {
                    _showRulesScreen();
                  }
                },
              ),
              const SizedBox(height: 16),
              ShoppingListCard(
                shoppingItems: shoppingItems,
                onAddItem: _addShoppingItem,
                onToggleItem: _toggleShoppingItem,
                onDeleteItem: _deleteShoppingItem,
                houseId: _houseId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
