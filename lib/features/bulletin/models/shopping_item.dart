import 'package:cloud_firestore/cloud_firestore.dart';
class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final String assignedTo;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final double? estimatedPrice;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.assignedTo,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.estimatedPrice,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      // Firestore Timestamp
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ShoppingItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      assignedTo: json['assignedTo'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      notes: json['notes'] as String?,
      estimatedPrice: _toDouble(json['estimatedPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'notes': notes,
      'estimatedPrice': estimatedPrice,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? assignedTo,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? estimatedPrice,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
    );
  }

  ShoppingItem toggleCompleted() {
    return copyWith(isCompleted: !isCompleted);
  }

  ShoppingItem assignTo(String member) {
    return copyWith(assignedTo: member);
  }

  ShoppingItem updateQuantity(String newQuantity) {
    return copyWith(quantity: newQuantity);
  }
}
