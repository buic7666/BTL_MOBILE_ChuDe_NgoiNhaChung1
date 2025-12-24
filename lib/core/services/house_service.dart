// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HouseService {
  static final HouseService _instance = HouseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory HouseService() {
    return _instance;
  }

  HouseService._internal();

  // Tạo mã nhà ngẫu nhiên 6 ký tự (chữ và số)
  Future<String> _generateHouseCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    int attempts = 0;

    while (true) {
      attempts++;
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      try {
        final existingHouses = await _firestore
            .collection('houses')
            .where('code', isEqualTo: code)
            .limit(1)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException(
                'house code query timeout',
              ),
            );

        if (existingHouses.docs.isEmpty) {
          print('DEBUG: code $code available after $attempts attempts');
          return code; // Mã chưa tồn tại, dùng mã này
        } else {
          print('DEBUG: code $code existed, retry attempt $attempts');
        }
      } catch (e) {
        print('DEBUG: _generateHouseCode error: $e');
        rethrow;
      }

      if (attempts >= 10) {
        throw Exception('Unable to generate unique code after $attempts attempts');
      }
    }
  }

  // Tạo nhà mới cho user hiện tại và trả về mã nhà
  Future<String?> createHouse({
    required String userId,
    required String name,
    String? address,
  }) async {
    try {
      print('DEBUG: Generating house code...');
      // Tạo mã nhà mới
      final houseCode = await _generateHouseCode();
      final now = DateTime.now();

      print('DEBUG: Generated house code: $houseCode');

      // Tạo document mới trong Firestore
      final houseDoc = _firestore.collection('houses').doc();

      print('DEBUG: Creating house document with id: ${houseDoc.id}');

      try {
        await houseDoc.set({
          'id': houseDoc.id,
          'code': houseCode,
          'name': name,
          'address': address ?? '',
          'ownerId': userId,
          'members': [userId],
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        }).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('DEBUG: houseDoc.set() timeout!');
            throw TimeoutException('Firestore set timeout');
          },
        );
        print('DEBUG: House document created. Now updating user document...');
      } catch (setError) {
        print('DEBUG: Error in houseDoc.set(): $setError');
        print('DEBUG: Error type: ${setError.runtimeType}');
        return null;
      }

      // Cập nhật (upsert) user document với houseId
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .set({
          'houseId': houseDoc.id,
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
        print('DEBUG: User document updated with houseId');
      } catch (updateError) {
        print('DEBUG: Error updating user doc: $updateError');
        // Nếu update fail, xóa house doc mới tạo
        await houseDoc.delete();
        print('DEBUG: Rolled back - deleted house document');
        return null;
      }

      print('House created for user $userId: $name with code $houseCode');
      return houseCode;
    } catch (e) {
      print('Error creating house: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  // Lấy tên nhà của user
  Future<String> getHouseName(String? userId) async {
    if (userId == null) return 'Nhà của bạn';

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final houseId = userDoc.data()?['houseId'];

      if (houseId == null) return 'Nhà của bạn';

      final houseDoc = await _firestore.collection('houses').doc(houseId).get();
      return houseDoc.data()?['name'] ?? 'Nhà của bạn';
    } catch (e) {
      print('Error getting house name: $e');
      return 'Nhà của bạn';
    }
  }

  // Lấy địa chỉ nhà của user
  Future<String?> getHouseAddress(String? userId) async {
    if (userId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final houseId = userDoc.data()?['houseId'];

      if (houseId == null) return null;

      final houseDoc = await _firestore.collection('houses').doc(houseId).get();
      return houseDoc.data()?['address'];
    } catch (e) {
      print('Error getting house address: $e');
      return null;
    }
  }

  // Kiểm tra user có nhà chưa
  Future<bool> hasHouse(String? userId) async {
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['houseId'] != null;
    } catch (e) {
      print('Error checking house: $e');
      return false;
    }
  }

  // Xóa thông tin nhà của user (rời nhà)
  Future<void> clearHouse(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'houseId': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error clearing house: $e');
    }
  }

  // Tham gia nhà bằng mã
  Future<bool> joinHouseByCode({
    required String userId,
    required String houseCode,
  }) async {
    try {
      // Tìm nhà theo mã
      final housesQuery = await _firestore
          .collection('houses')
          .where('code', isEqualTo: houseCode)
          .limit(1)
          .get();

      if (housesQuery.docs.isEmpty) {
        print('House code not found: $houseCode');
        return false;
      }

      final houseDoc = housesQuery.docs.first;
      final houseId = houseDoc.id;
      final now = DateTime.now();

      // Thêm userId vào members của nhà
      await _firestore.collection('houses').doc(houseId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Cập nhật (upsert) user document với houseId
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
        'houseId': houseId,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      print('User $userId joined house with code $houseCode');
      return true;
    } catch (e) {
      print('Error joining house by code: $e');
      return false;
    }
  }

  // Lấy mã nhà của user (nếu có)
  Future<String?> getHouseCode(String? userId) async {
    if (userId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final houseId = userDoc.data()?['houseId'];

      if (houseId == null) return null;

      final houseDoc = await _firestore.collection('houses').doc(houseId).get();
      return houseDoc.data()?['code'];
    } catch (e) {
      print('Error getting house code: $e');
      return null;
    }
  }
}
