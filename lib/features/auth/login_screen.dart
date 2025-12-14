import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../house_setup/welcome_house_screen.dart';
import '../../core/utils/app_utils.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController(); // email or phone
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoController.repeat(reverse: true);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        email: _contactController.text.trim(),
        password: _passwordController.text,
      );

      if (result) {
        final user = await _authService.getCurrentUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Đăng nhập thành công!'),
              backgroundColor: Color.fromARGB(255, 56, 56, 142),
            ),
          );

          if (user != null) {
            // Sau khi đăng nhập thành công, luôn đi tới WelcomeHouseScreen
            // User có thể chọn "Tạo Nhà Mới" hoặc "Gia nhập nhà bằng Mã"
            print('DEBUG: Navigating to WelcomeHouseScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeHouseScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Đăng nhập thất bại! Vui lòng kiểm tra thông tin.',
              ),
              backgroundColor: Color.fromARGB(255, 229, 57, 53),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Thoát ứng dụng hoặc về màn hình trước (nếu có)
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Background decorative shapes
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentGreen.withOpacity(0.06),
                    AppColors.accentBlue.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(160),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 28.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Animated logo: scale + fade
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 21, 2, 231),
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
                                size: 48,
                                color: AppColors.bgWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Đăng nhập tại đây',
                          style: TextStyle(
                            color: Color.fromARGB(255, 38, 12, 241),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chào mừng bạn! Vui lòng đăng nhập để tiếp tục.',
                          style: TextStyle(
                            color: Color.fromARGB(255, 9, 9, 9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                    // Form area
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Contact field - email or phone (accepts both)
                          TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email hoặc số điện thoại';
                              }
                              // Basic validation: either email format or numeric phone
                              final isEmail = value.contains('@');
                              if (isEmail && !AppUtils.isValidEmail(value)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Email hoặc Số điện thoại',
                              hintText: 'example@mail.com hoặc 0123456789',
                              filled: true,
                              fillColor: AppColors.accentGreen.withOpacity(
                                0.08,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.accentGreen,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.accentGreen,
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password field - subtle border, gray-blue background
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Vui lòng nhập mật khẩu';
                              if (!AppUtils.isValidPassword(value))
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              filled: true,
                              fillColor: AppColors.bgGrey.withOpacity(0.6),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight.withOpacity(0.6),
                                  width: 0.6,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.borderMedium,
                                  width: 1.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),

                          // Forgot password align right
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Bạn quên mật khẩu?',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 7, 7, 7),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Login button - prominent
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                38,
                                10,
                                251,
                              ),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.bgWhite,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 11, 11, 11),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer - create account and social
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Tạo tài khoản mới',
                            style: TextStyle(
                              color: Color.fromARGB(255, 14, 14, 14),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tiếp tục với',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Social buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Google',
                              onTap: () {
                                // TODO: implement Google sign-in
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildSocialButton(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              onTap: () {
                                // TODO: implement Facebook sign-in
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildSocialButton(
                              icon: Icons.apple,
                              label: 'Apple',
                              onTap: () {
                                // TODO: implement Apple sign-in
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.bgWhite,
        child: Icon(icon, color: AppColors.accentBlue),
      ),
    );
  }
}
