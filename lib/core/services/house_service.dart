// ignore_for_file: avoid_print

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HouseService {
  static final HouseService _instance = HouseService._internal();
  // Lazy access to Firestore to avoid web init timing issues
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  factory HouseService() {
    return _instance;
  }

  HouseService._internal();

  // Tạo mã nhà ngẫu nhiên 6 ký tự (chữ và số)
  String _generateHouseCodeLocal() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Tạo mã nhà đảm bảo không trùng trong Firestore
  Future<String> _generateUniqueHouseCode() async {
    for (int i = 0; i < 20; i++) {
      final code = _generateHouseCodeLocal();
      final snap = await _firestore
          .collection('houses')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return code;
    }
    // Fallback (rất hiếm khi xảy ra)
    return '${_generateHouseCodeLocal()}X';
  }

  // Tạo nhà mới cho user hiện tại và trả về mã nhà
  Future<String?> createHouse({
    required String userId,
    required String name,
    String? address,
  }) async {
    try {
      final code = await _generateUniqueHouseCode();
      final now = DateTime.now();

      final houseRef = await _firestore.collection('houses').add({
        'name': name,
        'address': address ?? '',
        'ownerId': userId,
        'code': code,
        'members': [userId],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Gán houseId cho user
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'houseId': houseRef.id,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      print('House created: $name (code=$code, id=${houseRef.id})');
      return code;
    } catch (e) {
      print('Error creating house: $e');
      return null;
    }
  }

  // Tham gia nhà bằng mã
  Future<bool> joinHouseByCode({
    required String userId,
    required String houseCode,
  }) async {
    try {
      final code = houseCode.toUpperCase().trim();
      final query = await _firestore
          .collection('houses')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('House code not found in Firestore: $code');
        return false;
      }

      final houseDoc = query.docs.first;
      final houseId = houseDoc.id;

      final batch = _firestore.batch();
      final houseRef = _firestore.collection('houses').doc(houseId);
      final userRef = _firestore.collection('users').doc(userId);

      batch.update(houseRef, {
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      batch.set(userRef, {
        'uid': userId,
        'houseId': houseId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      await batch.commit();
      print('User $userId joined house ${houseDoc['name']} (id=$houseId)');
      return true;
    } catch (e) {
      print('Error joining house by code: $e');
      return false;
    }
  }

  // Kiểm tra user có house chưa
  Future<bool> hasHouse(String? userId) async {
    if (userId == null) return false;
    final id = await getHouseId(userId);
    return id != null;
  }

  // Lấy mã nhà của user (nếu có)
  Future<String?> getHouseCode(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['code'] as String?;
  }

  // Lấy ID nhà của user (nếu có)
  Future<String?> getHouseId(String? userId) async {
    if (userId == null) return null;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['houseId'] as String?;
  }

  // Lấy tên nhà
  Future<String?> getHouseName(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['name'] as String?;
  }

  // Lấy địa chỉ nhà
  Future<String?> getHouseAddress(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['address'] as String?;
  }

  // Rời nhà (xoá houseId khỏi user, không sửa nhà)
  Future<void> clearHouse(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'houseId': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}
