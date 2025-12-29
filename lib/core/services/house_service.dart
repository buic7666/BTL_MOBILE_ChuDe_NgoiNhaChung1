// ignore_for_file: avoid_print

import 'dart:math';

class HouseService {
  static final HouseService _instance = HouseService._internal();

  factory HouseService() {
    return _instance;
  }

  HouseService._internal();

  // Mock house data - Map từ userId -> house info
  final Map<String, Map<String, String?>> _userHouses = {};

  // Mock house codes - Map từ houseCode -> house info
  final Map<String, Map<String, String>> _houseCodes = {
    'DEMO01': {
      'name': 'Nhà Demo',
      'address': '123 Đường Demo, Hà Nội',
      'ownerId': 'demo@demo.com',
    },
  };

  // Tạo mã nhà ngẫu nhiên 6 ký tự (chữ và số)
  String _generateHouseCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;

    // Tạo mã mới cho đến khi không trùng
    do {
      code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
    } while (_houseCodes.containsKey(code));

    return code;
  }

  // Tạo nhà mới cho user hiện tại và trả về mã nhà
  Future<String?> createHouse({
    required String userId,
    required String name,
    String? address,
  }) async {
    try {
      // Tạo mã nhà mới
      final houseCode = _generateHouseCode();

      // Lưu vào _houseCodes
      _houseCodes[houseCode] = {
        'name': name,
        'address': address ?? '',
        'ownerId': userId,
      };

      // Lưu vào _userHouses
      _userHouses[userId] = {
        'name': name,
        'address': address,
        'code': houseCode,
      };

      print('House created for user $userId: $name with code $houseCode');
      return houseCode;
    } catch (e) {
      print('Error creating house: $e');
      return null;
    }
  }

  // Lấy tên nhà của user
  String getHouseName(String? userId) {
    if (userId == null) return 'Nhà của bạn';
    return _userHouses[userId]?['name'] ?? 'Nhà của bạn';
  }

  // Lấy địa chỉ nhà của user
  String? getHouseAddress(String? userId) {
    if (userId == null) return null;
    return _userHouses[userId]?['address'];
  }

  // Kiểm tra user có nhà chưa
  bool hasHouse(String? userId) {
    if (userId == null) return false;
    return _userHouses.containsKey(userId);
  }

  // Xóa thông tin nhà của user (logout)
  void clearHouse(String userId) {
    _userHouses.remove(userId);
  }

  // Xóa tất cả
  void clearAll() {
    _userHouses.clear();
  }

  // Tham gia nhà bằng mã
  Future<bool> joinHouseByCode({
    required String userId,
    required String houseCode,
  }) async {
    try {
      // Kiểm tra mã nhà có tồn tại không
      if (!_houseCodes.containsKey(houseCode)) {
        print('House code not found: $houseCode');
        return false;
      }

      // Lấy thông tin nhà từ mã
      final houseInfo = _houseCodes[houseCode]!;

      // Gán nhà cho user
      _userHouses[userId] = {
        'name': houseInfo['name'],
        'address': houseInfo['address'],
        'code': houseCode,
      };

      print(
        'User $userId joined house: ${houseInfo['name']} with code $houseCode',
      );
      return true;
    } catch (e) {
      print('Error joining house by code: $e');
      return false;
    }
  }

  // Lấy mã nhà của user (nếu có)
  String? getHouseCode(String? userId) {
    if (userId == null) return null;
    return _userHouses[userId]?['code'];
  }

  // Lấy ID nhà của user (nếu có)
  Future<String?> getHouseId(String? userId) async {
    if (userId == null) return null;
    // In mock implementation, use houseCode as houseId
    return _userHouses[userId]?['code'];
  }
}
