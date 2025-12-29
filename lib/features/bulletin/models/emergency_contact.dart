import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;
  final String category; // 'official' or 'custom'
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return EmergencyContactModel(
      id: id,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'custom',
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'description': description,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
