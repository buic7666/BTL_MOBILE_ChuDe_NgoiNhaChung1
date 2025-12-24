// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/house_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  /// Tạo nhà mới
  Future<bool> createHouse({
    required String houseName,
    required String address,
    String? description,
    required String ownerId,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('houses').add({
        'name': houseName,
        'address': address,
        'description': description ?? '',
        'ownerId': ownerId,
        'members': [ownerId],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      print('House created successfully: $houseName');
      return true;
    } catch (e) {
      print('Create house error: $e');
      return false;
    }
  }

  /// Lấy thông tin nhà
  Future<HouseModel?> getHouse({required String houseId}) async {
    try {
      final doc = await _firestore.collection('houses').doc(houseId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return HouseModel(
        houseId: doc.id,
        houseName: data['name'] ?? '',
        address: data['address'] ?? '',
        description: data['description'],
        inviteCode: data['code'] ?? '',
        ownerId: data['ownerId'] ?? '',
        memberIds: List<String>.from(data['members'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      print('Get house error: $e');
      return null;
    }
  }

  /// Cập nhật thông tin nhà
  Future<bool> updateHouse({
    required String houseId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('houses').doc(houseId).update({
        ...data,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('House updated successfully: $houseId');
      return true;
    } catch (e) {
      print('Update house error: $e');
      return false;
    }
  }

  /// Xóa nhà
  Future<bool> deleteHouse({required String houseId}) async {
    try {
      await _firestore.collection('houses').doc(houseId).delete();
      print('House deleted successfully: $houseId');
      return true;
    } catch (e) {
      print('Delete house error: $e');
      return false;
    }
  }

  /// Tham gia nhà bằng invite code
  Future<bool> joinHouseByCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      final housesQuery = await _firestore
          .collection('houses')
          .where('code', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (housesQuery.docs.isEmpty) {
        print('House code not found: $inviteCode');
        return false;
      }

      final houseId = housesQuery.docs.first.id;
      await _firestore.collection('houses').doc(houseId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('User $userId joined house with code $inviteCode');
      return true;
    } catch (e) {
      print('Join house error: $e');
      return false;
    }
  }

  /// Lấy danh sách nhà của user
  Future<List<HouseModel>> getUserHouses({required String userId}) async {
    try {
      final housesQuery = await _firestore
          .collection('houses')
          .where('members', arrayContains: userId)
          .get();

      return housesQuery.docs.map((doc) {
        final data = doc.data();
        return HouseModel(
          houseId: doc.id,
          houseName: data['name'] ?? '',
          address: data['address'] ?? '',
          description: data['description'],
          inviteCode: data['code'] ?? '',
          ownerId: data['ownerId'] ?? '',
          memberIds: List<String>.from(data['members'] ?? []),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Get user houses error: $e');
      return [];
    }
  }
}
