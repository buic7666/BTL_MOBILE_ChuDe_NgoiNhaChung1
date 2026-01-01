// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'house_service.dart';
import '../../features/chores/models/chore.dart';

class ChoreService {
  static final ChoreService _instance = ChoreService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory ChoreService() => _instance;
  ChoreService._internal();

  /// Stream danh sách việc nhà theo `houseId`
  Stream<List<Chore>> choresStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('chores')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Chore.fromJson(d.data(), d.id))
            .toList());
  }

  /// Thêm việc nhà mới vào Firestore
  Future<bool> addChore({
    required String houseId,
    required String title,
    String? assignedToUid,
    String? assignedToName,
    String? frequency,
    DateTime? dueDate,
    int points = 1,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('chores')
          .add({
        'title': title,
        'assignedToUid': assignedToUid,
        'assignedToName': assignedToName,
        'frequency': frequency,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'completed': false,
        'points': points,
        'awarded': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      print('Chore added: $title (+$points điểm)');
      return true;
    } catch (e) {
      print('addChore error: $e');
      return false;
    }
  }

  /// Toggle trạng thái hoàn thành; nếu chuyển sang hoàn thành và chưa thưởng, cộng điểm cho user
  Future<Map<String, dynamic>> toggleComplete({
    required String houseId,
    required Chore chore,
  }) async {
    try {
        final docRef = _firestore
      final docRef = _firestore
          .collection('houses')
          .doc(houseId)
          .collection('chores')
          .doc(chore.id);

        // Người nhận điểm: ưu tiên assignedToUid, fallback người đang bấm
        final currentUser = AuthService().currentFirebaseUser;
        final uid = chore.assignedToUid ?? currentUser?.uid;
        final displayName = chore.assignedToName ??
          (currentUser?.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName!
            : (currentUser?.email?.split('@').first ?? 'Không xác định'));

      final newCompleted = !chore.isCompleted;
      final batch = _firestore.batch();
      batch.update(docRef, {
        'completed': newCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        // nếu đánh dấu hoàn thành, set awarded true để tránh cộng điểm lặp
        if (newCompleted) 'awarded': true,
        // Nếu chưa có người được gán, lưu lại người bấm hoàn thành
        if (newCompleted && chore.assignedToUid == null && uid != null)
          'assignedToUid': uid,
        if (newCompleted && chore.assignedToUid == null && uid != null)
          'assignedToName': displayName,
      });

      String? awardedUserName;
      int? awardedPoints;
      // Cộng điểm nếu hoàn thành, chưa awarded
      // Người nhận điểm: uid (đã lấy ở trên). Nếu vẫn null => không cộng điểm.
      if (newCompleted && !chore.awarded && uid != null) {
        final userRef = _firestore.collection('users').doc(uid);
        
        // Đảm bảo user document tồn tại, khởi tạo points = 0 nếu chưa có
        final userDoc = await userRef.get();
        if (!userDoc.exists) {
          batch.set(userRef, {
            'uid': uid,
            'points': chore.points,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          batch.update(userRef, {
            'points': FieldValue.increment(chore.points),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
        
        // Ưu tiên assignedToName từ chore, nếu không có thì lấy displayName/email
        awardedUserName = displayName;
        awardedPoints = chore.points;
        
        print('✓ Cộng ${chore.points} điểm cho: $awardedUserName');
      // Cộng điểm nếu hoàn thành và chưa awarded
      if (newCompleted && !chore.awarded) {
        final uid = chore.assignedToUid ?? AuthService().currentFirebaseUser?.uid;
        if (uid != null) {
          final userRef = _firestore.collection('users').doc(uid);
          
          // Đảm bảo user document tồn tại, khởi tạo points = 0 nếu chưa có
          final userDoc = await userRef.get();
          if (!userDoc.exists) {
            batch.set(userRef, {
              'uid': uid,
              'points': chore.points,
              'createdAt': Timestamp.fromDate(DateTime.now()),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          } else {
            batch.update(userRef, {
              'points': FieldValue.increment(chore.points),
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            });
          }
          
          // Ưu tiên assignedToName từ chore, không lấy từ user login
          awardedUserName = chore.assignedToName ?? 'Không xác định';
          awardedPoints = chore.points;
          
          print('✓ Cộng ${chore.points} điểm cho: $awardedUserName');
        }
      }

      await batch.commit();
      print('Chore ${chore.id} toggled: completed=$newCompleted');
      
      return {
        'success': true,
        'completed': newCompleted,
        'awardedUserName': awardedUserName,
        'awardedPoints': awardedPoints,
      };
    } catch (e) {
      print('toggleComplete error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  /// Xóa một chore
  Future<bool> deleteChore({
    required String houseId,
    required String choreId,
  }) async {
    try {
      await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('chores')
          .doc(choreId)
          .delete();
      print('Chore $choreId deleted');
      return true;
    } catch (e) {
      print('deleteChore error: $e');
      return false;
    }
  }

  /// Cập nhật một chore
  Future<bool> updateChore({
    required String houseId,
    required String choreId,
    required String title,
    String? assignedToName,
    String? frequency,
    int points = 1,
  }) async {
    try {
      await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('chores')
          .doc(choreId)
          .update({
        'title': title,
        'assignedToName': assignedToName,
        'frequency': frequency,
        'points': points,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Chore $choreId updated');
      return true;
    } catch (e) {
      print('updateChore error: $e');
      return false;
    }
  }
  /// Tiện ích: lấy `houseId` hiện tại của user
  Future<String?> currentUserHouseId() async {
      final uid = AuthService().currentFirebaseUser?.uid;
      if (uid == null) return null;
      return HouseService().getHouseId(uid);
  }
}
