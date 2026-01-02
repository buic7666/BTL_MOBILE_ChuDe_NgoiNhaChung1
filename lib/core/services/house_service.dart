// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/bulletin/models/house_info.dart';

class HouseService {
  static final HouseService _instance = HouseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory HouseService() => _instance;

  HouseService._internal();

  // ============ MEMBERS MANAGEMENT ============

  /// Lấy danh sách member IDs của house
  Future<List<String>> getHouseMembers(String houseId) async {
    try {
      final doc = await _firestore.collection('houses').doc(houseId).get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      // members có thể là Map hoặc List
      final membersData = data['members'];

      if (membersData is Map) {
        // Trường hợp members: { "uid1": true, "uid2": true }
        return membersData.keys
            .where((key) => membersData[key] == true)
            .map((key) => key.toString())
            .toList();
      } else if (membersData is List) {
        // Trường hợp members: ["uid1", "uid2"]
        return membersData.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      print('Error getting house members: $e');
      return [];
    }
  }

  /// Stream members của house (realtime)
  Stream<List<String>> houseMembersStream(String houseId) {
    return _firestore.collection('houses').doc(houseId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];

      final data = doc.data();
      if (data == null) return <String>[];

      final membersData = data['members'];

      if (membersData is Map) {
        return membersData.keys
            .where((key) => membersData[key] == true)
            .map((key) => key.toString())
            .toList();
      } else if (membersData is List) {
        return membersData.map((e) => e.toString()).toList();
      }

      return <String>[];
    });
  }

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
              onTimeout: () =>
                  throw TimeoutException('house code query timeout'),
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
        throw Exception(
          'Unable to generate unique code after $attempts attempts',
        );
      }
      String _generateHouseCodeLocal() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

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
    return '${_generateHouseCodeLocal()}X';
  }

  Future<String?> createHouse({
    required String userId,
    required String name,
    String? address,
  }) async {
    try {
      final code = await _generateUniqueHouseCode();
      final now = DateTime.now();
      print('DEBUG: Generated house code: $houseCode');

      // Tạo document mới trong Firestore
      final houseDoc = _firestore.collection('houses').doc();

      print('DEBUG: Creating house document with id: ${houseDoc.id}');

      try {
        await houseDoc
            .set({
              'id': houseDoc.id,
              'code': houseCode,
              'name': name,
              'address': address ?? '',
              'ownerId': userId,
              'members': [userId],
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            })
            .timeout(
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
        await _firestore.collection('users').doc(userId).set({
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
      final houseRef = _firestore.collection('houses').doc();
      await houseRef.set({
        'id': houseRef.id,
        'name': name,
        'address': address ?? '',
        'ownerId': userId,
        'code': code,
        'members': [userId],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

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

  Future<Map<String, dynamic>> joinHouseByCode({
    required String userId,
    required String houseCode,
  }) async {
    try {
      final code = houseCode.toUpperCase().trim();
      final housesQuery = await _firestore
          .collection('houses')
          .where('code', isEqualTo: code)
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('joinHouseByCode query timeout'),
          );

      if (housesQuery.docs.isEmpty) {
        return {'success': false, 'error': 'not-found'};
      }

      final houseDoc = housesQuery.docs.first;
      final houseId = houseDoc.id;
      final now = DateTime.now();

      final batch = _firestore.batch();
      final houseRef = _firestore.collection('houses').doc(houseId);
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(houseRef, {
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(now),
      });
      // Cập nhật (upsert) user document với houseId
      await _firestore.collection('users').doc(userId).set({
        'houseId': houseId,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      batch.set(
        userRef,
        {
          'uid': userId,
          'houseId': houseId,
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
      await batch.commit().timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('joinHouseByCode commit timeout'),
          );

      print('User $userId joined house with code $houseCode');
      return {'success': true, 'houseId': houseId};
    } on TimeoutException catch (e) {
      print('Timeout joining house: $e');
      return {'success': false, 'error': 'timeout'};
    } on FirebaseException catch (e) {
      print('FirebaseException joining house: ${e.code}');
      return {'success': false, 'error': e.code};
    } catch (e) {
      print('Error joining house by code: $e');
      return {'success': false, 'error': 'unknown'};
    }
  }

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

  Future<String?> getHouseId(String? userId) async {
    if (userId == null) return null;
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['houseId'] as String?;
    } catch (e) {
      print('Error getHouseId: $e');
      return null;
    }
  }

  Future<String?> getHouseCode(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['code'] as String?;
  }

  Future<String?> getHouseName(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['name'] as String?;
  }

  Future<String?> getHouseAddress(String? userId) async {
    final houseId = await getHouseId(userId);
    if (houseId == null) return null;
    final doc = await _firestore.collection('houses').doc(houseId).get();
    return doc.data()?['address'] as String?;
  }

  Future<void> clearHouse(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'houseId': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<HouseInfo?> getHouseInfoForUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final houseId = userDoc.data()?['houseId'] as String?;
      if (houseId == null) return null;

      final houseDoc = await _firestore.collection('houses').doc(houseId).get();
      final data = houseDoc.data();
      if (data == null) return null;

      return HouseInfo(
        id: data['id'] as String? ?? houseId,
        name: data['name'] as String? ?? '',
        inviteCode: data['code'] as String? ?? '',
        address: data['address'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        memberIds: List<String>.from(data['members'] ?? []),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error getHouseInfoForUser: $e');
      return null;
    }
  }
}
