import 'package:cloud_firestore/cloud_firestore.dart';

class Chore {
  final String id;
  final String title;
  final String? assignedToUid;
  final String? assignedToName;
  final DateTime? dueDate;
  final bool isCompleted;
  final int points;
  final bool awarded; // đã phát điểm hay chưa
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chore({
    required this.id,
    required this.title,
    this.assignedToUid,
    this.assignedToName,
    this.dueDate,
    this.isCompleted = false,
    this.points = 1,
    this.awarded = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chore.fromJson(Map<String, dynamic> json, String id) {
    return Chore(
      id: id,
      title: json['title'] as String? ?? '',
      assignedToUid: json['assignedToUid'] as String?,
      assignedToName: json['assignedToName'] as String?,
      dueDate: (json['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: json['completed'] as bool? ?? false,
      points: (json['points'] as num?)?.toInt() ?? 1,
      awarded: json['awarded'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  Chore copyWith({
    String? id,
    String? title,
    String? assignedToUid,
    String? assignedToName,
    DateTime? dueDate,
    bool? isCompleted,
    int? points,
    bool? awarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chore(
      id: id ?? this.id,
      title: title ?? this.title,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToName: assignedToName ?? this.assignedToName,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      points: points ?? this.points,
      awarded: awarded ?? this.awarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
