import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<EmergencyContact> contacts = [
      EmergencyContact(
        name: 'Công an',
        number: '113',
        icon: Icons.local_police,
        color: Colors.blue,
        description: 'Cảnh sát - Khẩn cấp',
      ),
      EmergencyContact(
        name: 'Cứu hỏa',
        number: '114',
        icon: Icons.fire_truck,
        color: Colors.red,
        description: 'Phòng cháy chữa cháy',
      ),
      EmergencyContact(
        name: 'Cấp cứu',
        number: '115',
        icon: Icons.local_hospital,
        color: Colors.green,
        description: 'Y tế khẩn cấp',
      ),
      EmergencyContact(
        name: 'Chủ nhà',
        number: '0987654321',
        icon: Icons.person,
        color: Colors.orange,
        description: 'Liên hệ chủ nhà',
      ),
      EmergencyContact(
        name: 'Ban quản lý tòa nhà',
        number: '0912345678',
        icon: Icons.apartment,
        color: Colors.purple,
        description: 'Quản lý chung cư',
      ),
      EmergencyContact(
        name: 'Bảo vệ',
        number: '0901234567',
        icon: Icons.security,
        color: Colors.teal,
        description: 'An ninh tòa nhà',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'SĐT Khẩn cấp',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Emergency Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk,
                  color: Colors.red.shade700,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Danh sách liên hệ khẩn cấp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Contacts List
              ...contacts.map((contact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildContactCard(context, contact),
                );
              }),

              const SizedBox(height: 16),

              // Warning Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lưu ý: Chỉ gọi số khẩn cấp khi thực sự cần thiết. Đối với các vấn đề thông thường, vui lòng liên hệ ban quản lý hoặc chủ nhà.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContact contact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: contact.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              contact.icon,
              color: contact.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  contact.number,
                  style: TextStyle(
                    fontSize: 15,
                    color: contact.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _makePhoneCall(context, contact.number),
                icon: Icon(
                  Icons.phone,
                  color: contact.color,
                  size: 24,
                ),
                tooltip: 'Gọi điện',
                style: IconButton.styleFrom(
                  backgroundColor: contact.color.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => _copyPhoneNumber(context, contact.number),
                icon: Icon(
                  Icons.copy,
                  color: Colors.grey[600],
                  size: 20,
                ),
                tooltip: 'Sao chép',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar(context, 'Không thể thực hiện cuộc gọi');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Lỗi: Không thể gọi điện');
    }
  }

  void _copyPhoneNumber(BuildContext context, String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép số điện thoại'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class EmergencyContact {
  final String name;
  final String number;
  final IconData icon;
  final Color color;
  final String description;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
    required this.description,
  });
}
