class HouseModel {
  final String houseId;
  final String houseName;
  final String address;
  final String? description;
  final String inviteCode;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseModel({
    required this.houseId,
    required this.houseName,
    required this.address,
    this.description,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) {
    return HouseModel(
      houseId: json['houseId'] as String,
      houseName: json['houseName'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'houseId': houseId,
      'houseName': houseName,
      'address': address,
      'description': description,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HouseModel copyWith({
    String? houseId,
    String? houseName,
    String? address,
    String? description,
    String? inviteCode,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HouseModel(
      houseId: houseId ?? this.houseId,
      houseName: houseName ?? this.houseName,
      address: address ?? this.address,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
