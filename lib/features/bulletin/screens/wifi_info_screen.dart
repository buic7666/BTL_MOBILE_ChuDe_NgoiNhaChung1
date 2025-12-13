import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WiFiInfoScreen extends StatelessWidget {
  const WiFiInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          'Thông tin mạng WiFi',
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
              // WiFi Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi,
                  color: Colors.blue.shade700,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),

              // Network Name Card
              _buildInfoCard(
                context,
                title: 'Tên mạng WiFi',
                value: 'Happy House WiFi',
                icon: Icons.wifi_tethering,
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 12),

              // Password Card
              _buildInfoCard(
                context,
                title: 'Mật khẩu',
                value: '123456789',
                icon: Icons.lock_outline,
                iconColor: Colors.orange,
                canCopy: true,
              ),
              const SizedBox(height: 12),

              // Network Type Card
              _buildInfoCard(
                context,
                title: 'Loại mạng',
                value: '2.4GHz & 5GHz',
                icon: Icons.router,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 12),

              // Speed Card
              _buildInfoCard(
                context,
                title: 'Tốc độ',
                value: '100 Mbps',
                icon: Icons.speed,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 12),

              // Connected Devices Card
              _buildInfoCard(
                context,
                title: 'Thiết bị đang kết nối',
                value: '8 thiết bị',
                icon: Icons.devices,
                iconColor: Colors.red,
              ),
              const SizedBox(height: 12),

              // Provider Card
              _buildInfoCard(
                context,
                title: 'Nhà cung cấp',
                value: 'Viettel',
                icon: Icons.business,
                iconColor: Colors.teal,
              ),
              const SizedBox(height: 24),

              // Note Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lưu ý: Không chia sẻ mật khẩu WiFi cho người ngoài. Nếu có thay đổi mật khẩu, vui lòng thông báo trong nhóm.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
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

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool canCopy = false,
  }) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mật khẩu'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: Icon(
                Icons.copy,
                color: Colors.grey[600],
                size: 20,
              ),
              tooltip: 'Sao chép',
            ),
        ],
      ),
    );
  }
}
