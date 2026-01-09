import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../../../core/services/house_service.dart';
import '../../../core/services/bulletin_service.dart';
import '../models/wifi_info.dart';

class WiFiInfoScreen extends StatefulWidget {
  const WiFiInfoScreen({super.key});

  @override
  State<WiFiInfoScreen> createState() => _WiFiInfoScreenState();
}

class _WiFiInfoScreenState extends State<WiFiInfoScreen> {
  List<WiFiInfo> wifiList = [];
  StreamSubscription<List<WiFiInfo>>? _wifiSub;
  String? _houseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = AuthService();
    final houseService = HouseService();
    final uid = auth.currentFirebaseUser?.uid;

    String? houseId;
    if (uid != null) {
      houseId = await houseService.getHouseId(uid);
    }

    if (!mounted) return;

    setState(() => _houseId = houseId);

    if (houseId != null) {
      _wifiSub?.cancel();
      _wifiSub = BulletinService().wifiInfoStream(houseId).listen((items) {
        if (!mounted) return;
        setState(() {
          wifiList = items;
          _loading = false;
        });
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _wifiSub?.cancel();
    super.dispose();
  }

  void _showAddWiFiDialog() {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final typeController = TextEditingController(text: '2.4GHz & 5GHz');
    final speedController = TextEditingController(text: '100 Mbps');
    final providerController = TextEditingController(text: 'Viettel');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Thêm thông tin WiFi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField('Tên mạng WiFi *', nameController),
                const SizedBox(height: 12),
                _buildTextField('Mật khẩu *', passwordController),
                const SizedBox(height: 12),
                _buildTextField('Loại mạng', typeController),
                const SizedBox(height: 12),
                _buildTextField('Tốc độ', speedController),
                const SizedBox(height: 12),
                _buildTextField('Nhà cung cấp', providerController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Vui lòng nhập tên và mật khẩu')),
                            );
                            return;
                          }

                          final wifi = WiFiInfo(
                            id: '',
                            networkName: nameController.text,
                            password: passwordController.text,
                            networkType: typeController.text,
                            speed: speedController.text,
                            provider: providerController.text,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await BulletinService().addWiFiInfo(_houseId!, wifi);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thêm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin mạng WiFi'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
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
        actions: [
          if (_houseId != null)
            IconButton(
              onPressed: _showAddWiFiDialog,
              icon: const Icon(Icons.add, color: Colors.blue),
              tooltip: 'Thêm WiFi',
            ),
        ],
      ),
      body: wifiList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông tin WiFi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (_houseId != null)
                    ElevatedButton.icon(
                      onPressed: _showAddWiFiDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm WiFi đầu tiên'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                    ...wifiList.map((wifi) {
                      return Column(
                        children: [
                          _buildInfoCard(
                            context,
                            title: 'Tên mạng WiFi',
                            value: wifi.networkName,
                            icon: Icons.wifi_tethering,
                            iconColor: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            title: 'Mật khẩu',
                            value: wifi.password,
                            icon: Icons.lock_outline,
                            iconColor: Colors.orange,
                            canCopy: true,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            title: 'Loại mạng',
                            value: wifi.networkType,
                            icon: Icons.router,
                            iconColor: Colors.purple,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            title: 'Tốc độ',
                            value: wifi.speed,
                            icon: Icons.speed,
                            iconColor: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            title: 'Nhà cung cấp',
                            value: wifi.provider,
                            icon: Icons.business,
                            iconColor: Colors.teal,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
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
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
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
            child: Icon(icon, color: iconColor, size: 24),
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
              icon: Icon(Icons.copy, color: Colors.grey[600], size: 20),
              tooltip: 'Sao chép',
            ),
        ],
      ),
    );
  }
}
