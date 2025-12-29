import 'package:cloud_firestore/cloud_firestore.dart';

class Chore {
  final String id;
  final String title;
  final String? assignedToUid;
  final String? assignedToName;
  final DateTime? dueDate;
  final bool isCompleted;
  final int points;
  final bool awarded;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chore({
    required this.id,
    required this.title,
    this.assignedToUid,
    this.assignedToName,
    this.dueDate,
    required this.isCompleted,
    required this.points,
    required this.awarded,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chore.fromJson(Map<String, dynamic> json, String id) {
    return Chore(
      id: id,
      title: json['title'] as String? ?? '',
      assignedToUid: json['assignedToUid'] as String?,
      assignedToName: json['assignedToName'] as String?,
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : null,
      isCompleted: json['completed'] as bool? ?? false,
      points: json['points'] as int? ?? 1,
      awarded: json['awarded'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completed': isCompleted,
      'points': points,
      'awarded': awarded,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
