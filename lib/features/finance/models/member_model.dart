import 'package:flutter/material.dart';

/// Model đại diện cho một thành viên trong nhà
class MemberModel {
  final String id;
  final String name;
  final Color color;

  MemberModel({required this.id, required this.name, required this.color});

  /// Danh sách thành viên mặc định
  static List<MemberModel> getDefaultMembers() {
    return [
      MemberModel(id: 'you', name: 'Bạn', color: const Color(0xFF8E54E9)),
      MemberModel(id: 'an', name: 'An', color: const Color(0xFF5A31D8)),
      MemberModel(id: 'binh', name: 'Bình', color: const Color(0xFF80CBC4)),
      MemberModel(id: 'chi', name: 'Chi', color: const Color(0xFFEF9A9A)),
    ];
  }

  /// Chuyển về Map để dễ sử dụng
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color};
  }
}
