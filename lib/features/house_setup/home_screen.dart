import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../common_widgets/custom_button.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../core/services/auth_service.dart';
import 'welcome_house_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  void _checkAuthAndRedirect() {
    // Defer until after first frame to avoid build-context issues
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (AuthService().isAuthenticated) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeHouseScreen()),
          );
        }
      } catch (_) {
        // If anything fails, stay on HomeScreen gracefully
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Branding Area (centered)
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 24, 9, 232),
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
                        size: 64,
                        color: AppColors.bgWhite,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'House Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trợ lý quản lý căn nhà tiện lợi cho cuộc sống chung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacing area
              const Spacer(flex: 2),

              // Action Area - two buttons in a row at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Đăng Nhập',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        width: double.infinity,
                        backgroundColor: const Color.fromARGB(255, 6, 49, 244),
                        textColor: AppColors.bgWhite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: 'Đăng Ký',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        width: double.infinity,
                        backgroundColor: const Color.fromARGB(255, 6, 49, 244),
                        textColor: AppColors.bgWhite,
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
}
