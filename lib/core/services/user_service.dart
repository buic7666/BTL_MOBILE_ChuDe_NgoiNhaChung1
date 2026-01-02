import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ GET USER INFO ============

  /// Lấy user profile từ UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserProfile(
        uid: uid,
        email: data['email'] as String?,
        name: data['name'] as String? ?? 'Unknown',
        avatar: data['avatar'] as String?,
        phone: data['phone'] as String?,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Lấy nhiều user profiles cùng lúc
  Future<Map<String, UserProfile>> getUserProfiles(List<String> uids) async {
    final Map<String, UserProfile> result = {};

    if (uids.isEmpty) return result;

    try {
      // Firestore 'in' query giới hạn 10 items, nên chia batch
      for (int i = 0; i < uids.length; i += 10) {
        final batch = uids.skip(i).take(10).toList();
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          result[doc.id] = UserProfile(
            uid: doc.id,
            email: data['email'] as String?,
            name: data['name'] as String? ?? 'Unknown',
            avatar: data['avatar'] as String?,
            phone: data['phone'] as String?,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }
      }

      return result;
    } catch (e) {
      return result;
    }
  }

  /// Stream user profile (realtime)
  Stream<UserProfile?> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return UserProfile(
        uid: uid,
        email: data['email'] as String?,
        name: data['name'] as String? ?? 'Unknown',
        avatar: data['avatar'] as String?,
        phone: data['phone'] as String?,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  /// Lấy tên hiển thị của user
  Future<String> getDisplayName(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.name ?? 'Unknown';
  }
}
