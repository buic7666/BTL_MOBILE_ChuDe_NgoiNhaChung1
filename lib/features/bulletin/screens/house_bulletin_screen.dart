import 'package:flutter/material.dart';
import '../widgets/house_info_card.dart';
import '../widgets/utility_grid.dart';
import '../widgets/shopping_list_card.dart';
import '../models/house_info.dart';
import '../models/utility.dart';
import '../models/shopping_item.dart';
import 'rules_screen.dart';
import 'wifi_info_screen.dart';
import 'emergency_contact_screen.dart';

class HouseBulletinScreen extends StatefulWidget {
  const HouseBulletinScreen({Key? key}) : super(key: key);

  @override
  State<HouseBulletinScreen> createState() => _HouseBulletinScreenState();
}

class _HouseBulletinScreenState extends State<HouseBulletinScreen> {
  late HouseInfo houseInfo;
  late List<Utility> utilities;
  late List<ShoppingItem> shoppingItems;
  late List<String> rules;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    houseInfo = HouseInfo(
      id: 'house1',
      name: 'Phòng 401 - Happy House',
      inviteCode: '882910',
      address: 'Địa chỉ mẫu',
      memberCount: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

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
  }

  void _addShoppingItem(ShoppingItem item) {
    setState(() {
      shoppingItems.add(item);
    });
  }

  void _toggleShoppingItem(int index) {
    setState(() {
      shoppingItems[index] = shoppingItems[index].toggleCompleted();
    });
  }

  void _deleteShoppingItem(int index) {
    setState(() {
      shoppingItems.removeAt(index);
    });
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

  @override
  Widget build(BuildContext context) {
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
              HouseInfoCard(houseInfo: houseInfo),
              const SizedBox(height: 16),
              UtilityGrid(
                utilities: utilities,
                onUtilityTap: (index) {
                  if (index == 0) {
                    _showWiFiInfoScreen();
                  } else if (index == 1) {
                    _showEmergencyContactScreen();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
