import 'package:cloud_firestore/cloud_firestore.dart';

class WiFiInfo {
  final String id;
  final String networkName;
  final String password;
  final String networkType;
  final String speed;
  final String provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WiFiInfo({
    required this.id,
    required this.networkName,
    required this.password,
    required this.networkType,
    required this.speed,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WiFiInfo.fromJson(Map<String, dynamic> json, String id) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return WiFiInfo(
      id: id,
      networkName: json['networkName'] as String? ?? '',
      password: json['password'] as String? ?? '',
      networkType: json['networkType'] as String? ?? '',
      speed: json['speed'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'networkName': networkName,
      'password': password,
      'networkType': networkType,
      'speed': speed,
      'provider': provider,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
