import 'package:cloud_firestore/cloud_firestore.dart';

class HouseRule {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final List<String> details;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HouseRule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.details,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseRule.fromJson(Map<String, dynamic> json, String id) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return HouseRule(
      id: id,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: json['content'] as String? ?? '',
      details: List<String>.from(json['details'] ?? const <String>[]),
      createdBy: json['createdBy'] as String?,
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'details': details,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
