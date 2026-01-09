import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/services/auth_service.dart';
// Removed unused import to satisfy analyzer warnings
import 'create_house_screen.dart';
import 'enter_house_code_screen.dart';

class WelcomeHouseScreen extends StatefulWidget {
  const WelcomeHouseScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeHouseScreen> createState() => _WelcomeHouseScreenState();
}

class _WelcomeHouseScreenState extends State<WelcomeHouseScreen> {
  @override
  void initState() {
    super.initState();
    // Không tự động vào nhà; để người dùng tự chọn tạo/nhập mã
  }

  Future<bool> _onWillPop(BuildContext context) async {
    // Hiển thị dialog xác nhận đăng xuất
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận đăng xuất'),
            content: const Text('Bạn có muốn đăng xuất khỏi ứng dụng?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  // Đăng xuất
                  final authService = AuthService();
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              // Màn hình đầu tiên - hiển thị dialog đăng xuất
              final shouldLogout = await _onWillPop(context);
              if (shouldLogout && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Khối 1: Branding
                  const Spacer(flex: 2),
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 4, 16, 246),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_filled,
                          size: 44,
                          color: AppColors.bgWhite,
                        ),
                      ),
                      const SizedBox(height: 18),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Chào mừng đến với\n',
                              style: TextStyle(
                                color: Color.fromARGB(255, 22, 21, 21),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'HousePal!',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 32, 8, 243),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bắt đầu cuộc sống chung tiện nghi, vui vẻ và gắn kết!',
                        style: TextStyle(
                          color: Color.fromARGB(255, 32, 31, 31),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),

                  // Khối 2: Primary Actions
                  Column(
                    children: [
                      // Nút 1: Tạo Nhà Mới (Gradient)
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 6, 45, 239),
                                const Color.fromARGB(255, 42, 7, 241),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to create house screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateHouseScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Color.fromARGB(255, 241, 237, 237),
                            ),
                            label: const Text(
                              'Tạo Nhà Mới',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              foregroundColor: const Color.fromARGB(
                                255,
                                247,
                                246,
                                248,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nút 2: Gia nhập nhà bằng mã
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to enter house code screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EnterHouseCodeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.vpn_key, color: Colors.white),
                          label: const Text(
                            'Gia nhập nhà bằng Mã',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color.fromARGB(255, 13, 5, 235),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: const Color.fromARGB(
                              255,
                              13,
                              5,
                              235,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
