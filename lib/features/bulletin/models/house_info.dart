import 'package:cloud_firestore/cloud_firestore.dart'; // Bắt buộc import cái này để xử lý Timestamp

class HouseInfo {
  final String id;
  final String name;
  final String inviteCode; // Map từ trường 'code'
  final String address;
  final String ownerId; // Thêm cái này cho đủ DB
  final List<String> memberIds; // Map từ trường 'members'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getter để lấy số lượng thành viên tự động
  int get memberCount => memberIds.length;

  const HouseInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.address,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseInfo.fromJson(Map<String, dynamic> json) {
    return HouseInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      // Sửa 1: Map đúng tên trường trong DB là 'code'
      inviteCode: json['code'] as String? ?? '', 
      address: json['address'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      
      // Sửa 2: Xử lý mảng members từ DB
      memberIds: List<String>.from(json['members'] ?? []), 

      // Sửa 3: Xử lý Timestamp của Firestore chuyển sang DateTime
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': inviteCode, // Ghi lên DB phải là 'code'
      'address': address,
      'ownerId': ownerId,
      'members': memberIds, // Ghi mảng ID lên
      'createdAt': Timestamp.fromDate(createdAt), // Chuyển ngược về Timestamp
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HouseInfo copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? address,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HouseInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      address: address ?? this.address,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}