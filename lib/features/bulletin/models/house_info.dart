class HouseInfo {
  final String id;
  final String name;
  final String inviteCode;
  final String address;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HouseInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.address,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseInfo.fromJson(Map<String, dynamic> json) {
    return HouseInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      address: json['address'] as String,
      memberCount: json['memberCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'address': address,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HouseInfo copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? address,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HouseInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      address: address ?? this.address,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
