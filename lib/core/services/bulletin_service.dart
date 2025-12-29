import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/bulletin/models/shopping_item.dart';
import '../../features/bulletin/models/utility.dart';
import '../../features/bulletin/models/house_rule.dart';
import '../../features/bulletin/models/wifi_info.dart';
import '../../features/bulletin/models/emergency_contact.dart';

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

  // --- WiFi Info ---
  Stream<List<WiFiInfo>> wifiInfoStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('wifi_info')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WiFiInfo.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addWiFiInfo(String houseId, WiFiInfo wifi) async {
    final now = DateTime.now();
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('wifi_info')
        .add({
      'networkName': wifi.networkName,
      'password': wifi.password,
      'networkType': wifi.networkType,
      'speed': wifi.speed,
      'provider': wifi.provider,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateWiFiInfo(String houseId, WiFiInfo wifi) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('wifi_info')
        .doc(wifi.id)
        .update({
      'networkName': wifi.networkName,
      'password': wifi.password,
      'networkType': wifi.networkType,
      'speed': wifi.speed,
      'provider': wifi.provider,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteWiFiInfo(String houseId, String wifiId) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('wifi_info')
        .doc(wifiId)
        .delete();
  }

  // --- Emergency Contacts ---
  Stream<List<EmergencyContactModel>> emergencyContactsStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('emergency_contacts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContactModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> addEmergencyContact(String houseId, EmergencyContactModel contact) async {
    final now = DateTime.now();
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('emergency_contacts')
        .add({
      'name': contact.name,
      'phoneNumber': contact.phoneNumber,
      'description': contact.description,
      'category': contact.category,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateEmergencyContact(String houseId, EmergencyContactModel contact) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('emergency_contacts')
        .doc(contact.id)
        .update({
      'name': contact.name,
      'phoneNumber': contact.phoneNumber,
      'description': contact.description,
      'category': contact.category,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteEmergencyContact(String houseId, String contactId) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('emergency_contacts')
        .doc(contactId)
        .delete();
  }

  // --- Add Utility ---
  Future<void> addUtility(String houseId, Utility utility) async {
    final now = DateTime.now();
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('utilities')
        .add({
      'name': utility.name,
      'description': utility.description,
      'price': utility.price,
      'type': utility.type.index,
      'icon': utility.icon.codePoint,
      'color': utility.color.value,
      'isActive': utility.isActive,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateUtility(String houseId, Utility utility) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('utilities')
        .doc(utility.id)
        .update({
      'name': utility.name,
      'description': utility.description,
      'price': utility.price,
      'type': utility.type.index,
      'icon': utility.icon.codePoint,
      'color': utility.color.value,
      'isActive': utility.isActive,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> deleteUtility(String houseId, String utilityId) async {
    await _firestore
        .collection('houses')
        .doc(houseId)
        .collection('utilities')
        .doc(utilityId)
        .delete();
  }
}