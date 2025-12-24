import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/bulletin/models/shopping_item.dart';
import '../../features/bulletin/models/utility.dart';
import '../../features/bulletin/models/house_rule.dart';

class BulletinService {
  static final BulletinService _instance = BulletinService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory BulletinService() => _instance;

  BulletinService._internal();

  // --- Shopping list ---
  Stream<List<ShoppingItem>> shoppingItemsStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('shopping_items')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingItem.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  Future<void> addShoppingItem(String houseId, ShoppingItem item) async {
    final now = DateTime.now();
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('shopping_items')
        .add({
      'name': item.name,
      'quantity': item.quantity,
      'assignedTo': item.assignedTo,
      'isCompleted': item.isCompleted,
      'notes': item.notes,
      'estimatedPrice': item.estimatedPrice,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> toggleShoppingItem(String houseId, ShoppingItem item) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('shopping_items')
        .doc(item.id)
        .update({
      'isCompleted': !item.isCompleted,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteShoppingItem(String houseId, String itemId) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('shopping_items')
        .doc(itemId)
        .delete();
  }

  // --- Utilities (optional, read-only for now) ---
  Stream<List<Utility>> utilitiesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('utilities')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Utility.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  // --- Rules ---
  Stream<List<HouseRule>> rulesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rules')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HouseRule.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addRule(String houseId, HouseRule rule) async {
    final now = DateTime.now();
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rules')
        .add({
      'title': rule.title,
      'subtitle': rule.subtitle,
      'content': rule.content,
      'details': rule.details,
      'createdBy': rule.createdBy,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateRule(String houseId, HouseRule rule) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rules')
        .doc(rule.id)
        .update({
      'title': rule.title,
      'subtitle': rule.subtitle,
      'content': rule.content,
      'details': rule.details,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteRule(String houseId, String ruleId) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('rules')
        .doc(ruleId)
        .delete();
  }
}