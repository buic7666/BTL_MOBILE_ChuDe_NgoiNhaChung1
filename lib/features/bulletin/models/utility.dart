import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UtilityType {
  wifi,
  electricity,
  water,
  cleaning,
  internet,
  gas,
  parking,
  other,
}

class Utility {
  final String id;
  final String name;
  final String description;
  final String price;
  final UtilityType type;
  final IconData icon;
  final Color color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Utility({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.icon,
    required this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Utility.fromJson(Map<String, dynamic> json) {
    return Utility(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '',
      type: UtilityType.values[json['type'] as int],
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.parse(v);
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'type': type.index,
      'icon': icon.codePoint,
      'color': color.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Utility copyWith({
    String? id,
    String? name,
    String? description,
    String? price,
    UtilityType? type,
    IconData? icon,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Utility(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Utility.wifi({required String price}) {
    return Utility(
      id: 'wifi',
      name: 'Wifi',
      description: 'Internet tốc độ cao',
      price: price,
      type: UtilityType.wifi,
      icon: Icons.wifi,
      color: Colors.blue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Utility.electricSupply({required String price}) {
    return Utility(
      id: 'electricity',
      name: 'Điện & Nước',
      description: 'Chỉ số ngày 15',
      price: price,
      type: UtilityType.electricity,
      icon: Icons.electrical_services,
      color: Colors.orange,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Utility.sdt({required String price}) {
    return Utility(
      id: 'sdt',
      name: 'SĐT Khẩn cấp',
      description: 'Chi nháy, Công an',
      price: price,
      type: UtilityType.other,
      icon: Icons.phone,
      color: Colors.pink,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Utility.rules({required String price}) {
    return Utility(
      id: 'rules',
      name: 'Nội quy',
      description: 'Xem chi tiết ↓',
      price: price,
      type: UtilityType.other,
      icon: Icons.rule,
      color: Colors.purple,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
